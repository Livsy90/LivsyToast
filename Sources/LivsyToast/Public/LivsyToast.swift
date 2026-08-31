import SwiftUI

public extension View {
    /// Presents toasts from `center` as an overlapping stack in a pass-through overlay window.
    ///
    /// New toasts are placed in front. Only the front toast can be dragged; older toasts remain
    /// visible behind it and move forward as newer toasts are dismissed.
    func toastStack(
        center: ToastCenter,
        edge: VerticalEdge = .bottom,
        maximumVisibleToasts: Int = 3
    ) -> some View {
        modifier(
            ToastStackWindowModifier(
                center: center,
                edge: edge,
                maximumVisibleToasts: max(1, maximumVisibleToasts)
            )
        )
    }
}

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
    ///         Button("Show Toast") {
    ///            isToastPresented.toggle()
    ///         }
    ///         .toast(
    ///             isPresented: $isToastPresented,
    ///             duration: 2,
    ///             edge: .top
    ///         ) {
    ///             HStack(spacing: 12) {
    ///                 Image(systemName: "bell.fill")
    ///                     .foregroundStyle(.yellow)
    ///
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
    ///          Button("Show Toast") {
    ///             isToastPresented.toggle()
    ///         }
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

#Preview("Stacked toasts") {
    struct StackedToastDemo: View {
        @StateObject private var center = ToastCenter()
        @State private var didSeed = false
        @State private var nextToast = 4

        var body: some View {
            VStack(spacing: 16) {
                Button("Add toast") {
                    center.show("Toast #\(nextToast)", duration: nil)
                    nextToast += 1
                }

                Button("Dismiss all") {
                    center.dismissAll()
                }
            }
            .buttonStyle(.borderedProminent)
            .toastStack(center: center, edge: .bottom)
            .onAppear {
                guard !didSeed else { return }
                didSeed = true
                center.show("Saved successfully", duration: nil)
                center.show("Photo uploaded", duration: nil)
                center.show("Connection restored", duration: nil)
            }
        }
    }

    return StackedToastDemo()
}

#Preview("Single toast") {
    struct ToastDemo: View {
        @State private var isToastPresented: Bool = false

        var body: some View {
            Button("Show Toast") {
                isToastPresented.toggle()
            }
            .toast(
                isPresented: $isToastPresented,
                duration: 2,
                edge: .top
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.yellow)

                    Text("Custom content toast")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }

    return ToastDemo()
}

@available(iOS 16.0, *)
private struct SingleToastNavigationPreview: View {
    @State private var isToastPresented = false
    @State private var toastTitle = "Toast from the root screen"

    var body: some View {
        NavigationStack {
            List {
                Button("Show toast") {
                    showToast("Toast from the root screen")
                }

                NavigationLink("Open details") {
                    NavigationToastDetail {
                        showToast("Toast from the details screen")
                    }
                }
            }
            .navigationTitle("Root")
        }
        .toast(
            isPresented: $isToastPresented,
            duration: 8,
            edge: .top
        ) {
            Label(toastTitle, systemImage: "bell.fill")
                .font(.callout.weight(.semibold))
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
                .padding(20)
        }
    }

    private func showToast(_ title: String) {
        toastTitle = title
        isToastPresented = true
    }
}

@available(iOS 16.0, *)
private struct StackedToastNavigationPreview: View {
    @StateObject private var center = ToastCenter()

    var body: some View {
        NavigationStack {
            List {
                Button("Add toast") {
                    showToast("Toast from the root screen", icon: "house.fill")
                }

                NavigationLink("Open details") {
                    NavigationToastDetail {
                        showToast("Toast from the details screen", icon: "doc.fill")
                    }
                }
            }
            .navigationTitle("Root")
        }
        .toastStack(center: center, edge: .bottom)
    }

    private func showToast(_ title: String, icon: String) {
        center.show(duration: 8) {
            Label(title, systemImage: icon)
                .font(.callout.weight(.semibold))
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

@available(iOS 16.0, *)
private struct NavigationToastDetail: View {
    enum Action {
        case showToast
    }

    let onAction: (Action) -> Void

    init(onShowToast: @escaping () -> Void) {
        onAction = { action in
            switch action {
            case .showToast:
                onShowToast()
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("The toast presenter remains outside the navigation destination.")
                .multilineTextAlignment(.center)

            Button("Show toast over details") {
                onAction(.showToast)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Details")
    }
}

#Preview("Single toast · NavigationStack") {
    if #available(iOS 16.0, *) {
        SingleToastNavigationPreview()
    } else {
        Text("NavigationStack requires iOS 16 or later")
    }
}

#Preview("Stacked toasts · NavigationStack") {
    if #available(iOS 16.0, *) {
        StackedToastNavigationPreview()
    } else {
        Text("NavigationStack requires iOS 16 or later")
    }
}
