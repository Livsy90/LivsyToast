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
            ZStack {
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.24),
                        Color(uiColor: .systemBackground),
                        Color.cyan.opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        StackedToastHeroCard()

                        HStack(spacing: 12) {
                            StackedToastMetric(
                                value: "3",
                                title: "Visible layers",
                                icon: "square.3.layers.3d"
                            )
                            StackedToastMetric(
                                value: "8s",
                                title: "Demo duration",
                                icon: "timer"
                            )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("TRY THE STACK")
                                .font(.caption.weight(.bold))
                                .tracking(1.2)
                                .foregroundStyle(.secondary)

                            Button {
                                showToast(.success)
                            } label: {
                                StackedToastActionCard(
                                    title: "Add success toast",
                                    subtitle: "A larger glass card with a gradient accent",
                                    icon: "checkmark.circle.fill",
                                    colors: [.green, .mint]
                                )
                            }

                            Button {
                                showToast(.sync)
                            } label: {
                                StackedToastActionCard(
                                    title: "Add sync toast",
                                    subtitle: "Add several to see the layered presentation",
                                    icon: "arrow.triangle.2.circlepath",
                                    colors: [.blue, .cyan]
                                )
                            }

                            NavigationLink {
                                StackedToastNavigationDetail { kind in
                                    showToast(kind)
                                }
                            } label: {
                                StackedToastActionCard(
                                    title: "Open details",
                                    subtitle: "The stack remains above navigation changes",
                                    icon: "arrow.up.right.square.fill",
                                    colors: [.indigo, .purple]
                                )
                            }
                        }
                        .buttonStyle(.plain)

                        Text("Tip: swipe the front toast down to reveal the next card.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Toast Lab")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toastStack(center: center, edge: .bottom, maximumVisibleToasts: 3)
    }

    private func showToast(_ kind: StackedToastDemoKind) {
        center.show(duration: 8) {
            StackedToastDemoCard(kind: kind)
        }
    }
}

@available(iOS 16.0, *)
private enum StackedToastDemoKind {
    case success
    case sync
    case navigation

    var title: String {
        switch self {
        case .success: "Changes saved"
        case .sync: "Workspace synced"
        case .navigation: "Still with you"
        }
    }

    var subtitle: String {
        switch self {
        case .success: "Your latest updates are safely stored."
        case .sync: "Everything is up to date across devices."
        case .navigation: "This toast was presented from the details screen."
        }
    }

    var icon: String {
        switch self {
        case .success: "checkmark"
        case .sync: "arrow.triangle.2.circlepath"
        case .navigation: "location.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .success: [.green, .mint]
        case .sync: [.blue, .cyan]
        case .navigation: [.indigo, .purple]
        }
    }
}

@available(iOS 16.0, *)
private struct StackedToastDemoCard: View {
    let kind: StackedToastDemoKind

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: kind.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: kind.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(kind.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "sparkles")
                .font(.callout.weight(.semibold))
                .foregroundStyle(kind.colors[0])
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 88)
        .glassedEffect(
            in: RoundedRectangle(cornerRadius: 26, style: .continuous),
            interactive: true,
            tint: kind.colors[0].opacity(0.12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

@available(iOS 16.0, *)
private struct StackedToastHeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))

                Spacer()

                Text("LIVE DEMO")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.14), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Stacked notifications")
                    .font(.title2.weight(.bold))

                Text("Trigger multiple glass toasts, then navigate while the overlay stays in place.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.indigo, .purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .offset(x: 45, y: -65)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }
}

@available(iOS 16.0, *)
private struct StackedToastMetric: View {
    let value: String
    let title: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.indigo)
                Spacer()
                Text(value)
                    .font(.title3.weight(.bold))
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

@available(iOS 16.0, *)
private struct StackedToastActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

@available(iOS 16.0, *)
private struct StackedToastNavigationDetail: View {
    enum Action {
        case showToast(StackedToastDemoKind)
    }

    let onAction: (Action) -> Void

    init(onShowToast: @escaping (StackedToastDemoKind) -> Void) {
        onAction = { action in
            switch action {
            case let .showToast(kind):
                onShowToast(kind)
            }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color(uiColor: .systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )

                VStack(spacing: 8) {
                    Text("A different destination")
                        .font(.title2.weight(.bold))

                    Text("The same ToastCenter still presents above this screen and the navigation transition.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    onAction(.showToast(.navigation))
                } label: {
                    Label("Show toast here", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
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
