import SwiftUI

public extension View {
    /// Presents a custom toast view in a separate overlay window above the current UI.
    ///
    /// This modifier displays a transient, lightweight message or UI (the `content` you provide)
    /// from either the top or bottom edge of the screen. It supports:
    /// - Automatic dismissal after an optional duration
    /// - Manual dismissal by toggling `isPresented`
    /// - Edge selection (`.top` or `.bottom`)
    /// - Drag-to-dismiss interaction in the direction of the edge
    /// - Optional `onDismiss` callback fired after the toast fully disappears
    ///
    /// The toast is hosted in a transparent, pass-through overlay window so it does not block
    /// touches to underlying content except where the toast itself is visible and interactive.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls whether the toast is visible. Set to `true` to show the toast and `false` to hide it.
    ///   - duration: Optional auto-dismiss duration in seconds. If `nil` or `<= 0`, the toast will not auto-dismiss.
    ///   - edge: The vertical edge from which the toast appears (`.top` or `.bottom`). Default is `.bottom`.
    ///   - onDismiss: An optional closure called after the toast finishes dismissing (including animation).
    ///   - content: A view builder that provides the custom content of the toast.
    /// - Returns: A view that conditionally presents the toast based on `isPresented`.
    ///
    /// Example:
    /// ```swift
    /// struct ToastDemo: View {
    ///     @State private var isToastPresented: Bool = false
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             Button("Show Toast") {
    ///                 isToastPresented.toggle()
    ///             }
    ///         }
    ///         .frame(maxWidth: .infinity)
    ///         .toast(
    ///             isPresented: $isToastPresented,
    ///             duration: 2,
    ///             edge: .top
    ///         ) {
    ///             HStack(spacing: 12) {
    ///                 Image(systemName: "bell.fill").foregroundStyle(.yellow)
    ///                 Text("Custom content toast")
    ///                     .font(.callout)
    ///                     .fontWeight(.semibold)
    ///             }
    ///             .padding(.horizontal, 16)
    ///             .padding(.vertical, 12)
    ///             .background(
    ///                 RoundedRectangle(cornerRadius: 20, style: .continuous)
    ///                     .fill(.ultraThinMaterial)
    ///             )
    ///         }
    ///     }
    /// }
    /// ```
    func toast<T: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval? = 4,
        edge: VerticalEdge = .bottom,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> T
    ) -> some View {
        modifier(
            ToastWindowModifier(
                isPresented: isPresented,
                duration: duration,
                edge: edge,
                onDismiss: onDismiss,
                toastView: content
            )
        )
    }
    
    /// Presents a standard text-based toast in a separate overlay window above the current UI.
    ///
    /// This convenience overload displays a styled `Text` message as a toast from either the top
    /// or bottom edge of the screen. It supports:
    /// - Automatic dismissal after an optional duration
    /// - Manual dismissal by toggling `isPresented`
    /// - Edge selection (`.top` or `.bottom`)
    /// - Drag-to-dismiss interaction in the direction of the edge
    /// - Optional `onDismiss` callback fired after the toast fully disappears
    ///
    /// The toast is hosted in a transparent, pass-through overlay window so it does not block
    /// touches to underlying content except where the toast itself is visible and interactive.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls whether the toast is visible. Set to `true` to show the toast and `false` to hide it.
    ///   - message: The string displayed inside the toast.
    ///   - duration: Optional auto-dismiss duration in seconds. If `nil` or `<= 0`, the toast will not auto-dismiss. Default is `4`.
    ///   - edge: The vertical edge from which the toast appears (`.top` or `.bottom`). Default is `.bottom`.
    ///   - onDismiss: An optional closure called after the toast finishes dismissing (including animation).
    /// - Returns: A view that conditionally presents the toast based on `isPresented`.
    ///
    /// Example:
    /// ```swift
    /// struct ToastDemo: View {
    ///     @State private var isToastPresented: Bool = false
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             Button("Show Toast") {
    ///                 isToastPresented.toggle()
    ///             }
    ///         }
    ///         .frame(maxWidth: .infinity)
    ///         .toast(
    ///             isPresented: $isToastPresented,
    ///             message: "Hello, this is a toast message!",
    ///             duration: 2,
    ///             edge: .top
    ///         )
    ///     }
    /// }
    /// ```
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        duration: TimeInterval? = 4,
        edge: VerticalEdge = .bottom,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(
            ToastWindowModifier(
                isPresented: isPresented,
                duration: duration,
                edge: edge,
                onDismiss: onDismiss,
                toastView: {
                    Text(message)
                        .font(.body)
                        .fontWeight(.medium)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(20)
                        .glassedEffect(in: .rect(cornerRadius: 33), interactive: true)
                        .contentShape(.rect)
                        .padding(20)
                }
            )
        )
    }
}

private extension View {
    func toastOverlay<T: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval? = 4,
        edge: VerticalEdge = .bottom,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> T
    ) -> some View {
        modifier(
            ToastOverlayModifier(
                isPresented: isPresented,
                duration: duration,
                edge: edge,
                onDismiss: onDismiss,
                toastView: content
            )
        )
    }
    
    @ViewBuilder
    func glassedEffect(
        in shape: some Shape,
        interactive: Bool = false,
        tint: Color? = nil
    ) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                self.glassEffect(.regular.tint(tint), in: shape)
            }
        } else {
            background(.ultraThinMaterial).clipShape(shape)
        }
    }
}

private struct ToastOverlayModifier<T: View>: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval?
    let edge: VerticalEdge
    let onDismiss: (() -> Void)?
    let toastView: () -> T
    private let animationDuration: TimeInterval = 0.3
    @State private var dismissTask: Task<Void, Never>? = nil
    @State private var dragOffsetY: CGFloat = 0
    private var aligment: Alignment {
        switch edge {
        case .top: .top
        case .bottom: .bottom
        }
    }
    private var transitionEdge: Edge {
        switch edge {
        case .top: .top
        case .bottom: .bottom
        }
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                guard !newValue else { return }
                cancelAutoDismiss()
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(animationDuration * 1_000_000_000))
                    onDismiss?()
                }
            }
            .overlay(alignment: aligment) {
                if isPresented {
                    toastView()
                        .offset(y: dragOffsetY)
                        .opacity(Double(max(CGFloat(0.5), 1 - abs(dragOffsetY) / 200)))
                        .gesture(
                            DragGesture(minimumDistance: 5, coordinateSpace: .local)
                                .onChanged { value in
                                    // Only track vertical drag in the correct direction relative to edge
                                    let dy = value.translation.height
                                    switch edge {
                                    case .bottom:
                                        // Allow dragging down (positive dy); clamp upwards movement to zero to avoid jitter
                                        dragOffsetY = max(0, dy)
                                    case .top:
                                        // Allow dragging up (negative dy); clamp downwards movement to zero
                                        dragOffsetY = min(0, dy)
                                    }
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 30
                                    let dy = value.translation.height
                                    var shouldDismiss = false
                                    switch edge {
                                    case .bottom:
                                        if dy > threshold { shouldDismiss = true }
                                    case .top:
                                        if dy < -threshold { shouldDismiss = true }
                                    }

                                    if shouldDismiss {
                                        // Trigger dismiss and reset offset
                                        withAnimation(.bouncy(duration: animationDuration)) {
                                            isPresented = false
                                        }
                                    } else {
                                        // Snap back
                                        withAnimation(.bouncy(duration: animationDuration)) {
                                            dragOffsetY = 0
                                        }
                                    }
                                }
                        )
                        .transition(.move(edge: transitionEdge).combined(with: .blurReplace))
                        .onAppear {
                            scheduleAutoDismiss()
                        }
                }
            }
            .animation(.bouncy, value: isPresented)
    }
    
    private func scheduleAutoDismiss() {
        guard let duration, duration > 0 else { return }
        cancelAutoDismiss()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled && isPresented {
                isPresented = false
            }
        }
    }
    
    private func cancelAutoDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }
}

private struct ToastWindowModifier<T: View>: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval?
    let edge: VerticalEdge
    let onDismiss: (() -> Void)?
    let toastView: () -> T
    @State private var overlay = OverlayWindow()
    @State private var isToastPresented: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    overlay.show {
                        Color.clear
                            .toastOverlay(
                                isPresented: $isToastPresented,
                                duration: duration,
                                edge: edge,
                                onDismiss: {
                                    overlay.hide()
                                    onDismiss?()
                                },
                                content: toastView
                            )
                            .preferredColorScheme(colorScheme)
                    }
                    
                    isToastPresented = true
                } else {
                    isToastPresented = false
                }
            }
            .onChange(of: isToastPresented) { _, newValue in
                if !newValue { isPresented = false }
            }
    }
}

/// Custom UIWindow that passes through touches in transparent/non-interactive areas
private final class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard
            let hitView = super.hitTest(point, with: event),
            let rootView = rootViewController?.view
        else {
            return nil
        }

        if #available(iOS 18, *) {
            for subview in rootView.subviews.reversed() {
                /// Finding if any of rootview's subview is receiving hit test
                let pointInSubview = subview.convert(point, from: rootView)
                if subview.hitTest(pointInSubview, with: event) != nil {
                    return hitView
                }
            }
            return nil
        } else {
            return hitView == rootView ? nil : hitView
        }
    }
}

@MainActor
private final class OverlayWindow {
    private var window: UIWindow?
    
    func show<Content: View>(@ViewBuilder content: () -> Content) {
        // Prefer the currently active (foreground) scene.
        let scenes = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let scene = scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first(where: { $0.activationState == .foregroundInactive })
            ?? scenes.first

        guard let scene else { return }

        let window = PassThroughWindow(windowScene: scene)
        let controller = UIHostingController(rootView: content())
        controller.view.backgroundColor = .clear

        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = controller
        window.isHidden = false
        
        self.window = window
    }
    
    func hide() {
        window?.isHidden = true
        window = nil
    }
}

#Preview {
    struct ToastDemo: View {
        @State private var isToastPresented: Bool = false
        
        var body: some View {
            ScrollView {
                Button("Show Toast") {
                    isToastPresented.toggle()
                }
            }
            .frame(maxWidth: .infinity)
            .toast(
                isPresented: $isToastPresented,
                message: "Hello, this is a toast message!",
                duration: 2,
                edge: .top
            )
        }
    }
    
    return ToastDemo()
}


