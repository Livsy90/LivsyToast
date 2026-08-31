import SwiftUI

struct ToastWindowModifier<T: View>: ViewModifier {
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
            .onChangeCompat(of: isPresented) { newValue in
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
                    withAnimation {
                        isToastPresented = true
                    }
                } else {
                    isToastPresented = false
                }
            }
            .onChangeCompat(of: isToastPresented) { newValue in
                if !newValue { isPresented = false }
            }
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
}

@available(iOS 17.0, *)
private func toastAnimationModern(duration: TimeInterval) -> Animation {
    .bouncy(duration: duration)
}

private func toastAnimation(duration: TimeInterval) -> Animation {
    if #available(iOS 17.0, *) {
        toastAnimationModern(duration: duration)
    } else {
        .spring(response: duration, dampingFraction: 0.75)
    }
}

@available(iOS 17.0, *)
private func toastPresentAnimationModern() -> Animation {
    .bouncy
}

private func toastPresentAnimation() -> Animation {
    if #available(iOS 17.0, *) {
        toastPresentAnimationModern()
    } else {
        .spring(response: 0.3, dampingFraction: 0.75)
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

    @ViewBuilder
    private func presentedToast() -> some View {
        toastView()
            .offset(y: dragOffsetY)
            .opacity(Double(max(CGFloat(0.5), 1 - abs(dragOffsetY) / 200)))
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .local)
                    .onChanged { value in
                        cancelAutoDismiss()
                        let dy = value.translation.height
                        switch edge {
                        case .bottom:
                            dragOffsetY = max(0, dy)
                        case .top:
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
                            withAnimation(toastAnimation(duration: animationDuration)) {
                                isPresented = false
                            }
                        } else {
                            scheduleAutoDismiss()
                            withAnimation(toastAnimation(duration: animationDuration)) {
                                dragOffsetY = 0
                            }
                        }
                    }
            )
            .onAppear {
                scheduleAutoDismiss()
            }
            .toastEntryTransition(edge: transitionEdge)
    }
    
    func body(content: Content) -> some View {
        content
            .onChangeCompat(of: isPresented) { newValue in
                guard !newValue else { return }
                cancelAutoDismiss()
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(animationDuration * 1_000_000_000))
                    onDismiss?()
                }
            }
            .overlay(alignment: aligment) {
                if isPresented {
                    presentedToast()
                }
            }
            .animation(toastPresentAnimation(), value: isPresented)
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
