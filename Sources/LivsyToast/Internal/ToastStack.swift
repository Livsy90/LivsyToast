import SwiftUI

struct ToastStackWindowModifier: ViewModifier {
    @ObservedObject var center: ToastCenter
    let edge: VerticalEdge
    let maximumVisibleToasts: Int

    @State private var overlay = OverlayWindow()
    @State private var hideTask: Task<Void, Never>?
    @StateObject private var configuration: ToastStackConfiguration
    @Environment(\.colorScheme) private var colorScheme

    init(
        center: ToastCenter,
        edge: VerticalEdge,
        maximumVisibleToasts: Int
    ) {
        self.center = center
        self.edge = edge
        self.maximumVisibleToasts = maximumVisibleToasts
        _configuration = StateObject(
            wrappedValue: ToastStackConfiguration(
                edge: edge,
                maximumVisibleToasts: maximumVisibleToasts
            )
        )
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                updateConfiguration()
                updateOverlay()
            }
            .onChangeCompat(of: center.entries.count) { _ in
                updateOverlay()
            }
            .onChangeCompat(of: edge) { _ in
                updateConfiguration()
            }
            .onChangeCompat(of: maximumVisibleToasts) { _ in
                updateConfiguration()
            }
            .onChangeCompat(of: colorScheme) { _ in
                updateConfiguration()
            }
            .onDisappear {
                hideTask?.cancel()
                overlay.hide()
            }
    }

    private func updateConfiguration() {
        configuration.update(
            edge: edge,
            maximumVisibleToasts: maximumVisibleToasts,
            colorScheme: colorScheme
        )
    }

    private func updateOverlay() {
        hideTask?.cancel()
        hideTask = nil

        if center.entries.isEmpty {
            hideTask = Task { @MainActor in
                try? await Task.sleep(
                    nanoseconds: UInt64(Constants.stackedToastAnimationDuration * 1_000_000_000)
                )
                guard !Task.isCancelled, center.entries.isEmpty else { return }
                overlay.hide()
            }
        } else if !overlay.isVisible {
            overlay.show {
                ToastStackOverlay(
                    center: center,
                    configuration: configuration
                )
            }
        }
    }
}

private func stackedToastAnimation() -> Animation {
    if #available(iOS 17.0, *) {
        return .bouncy(duration: Constants.stackedToastAnimationDuration)
    } else {
        return .spring(response: Constants.stackedToastAnimationDuration, dampingFraction: 0.75)
    }
}

private func stackedToastReflowAnimation() -> Animation {
    .easeOut(duration: Constants.stackedToastReflowDuration)
}

@MainActor
private final class ToastStackConfiguration: ObservableObject {
    @Published private(set) var edge: VerticalEdge
    @Published private(set) var maximumVisibleToasts: Int
    @Published private(set) var colorScheme: ColorScheme?

    init(
        edge: VerticalEdge,
        maximumVisibleToasts: Int,
        colorScheme: ColorScheme? = nil
    ) {
        self.edge = edge
        self.maximumVisibleToasts = max(1, maximumVisibleToasts)
        self.colorScheme = colorScheme
    }

    func update(
        edge: VerticalEdge,
        maximumVisibleToasts: Int,
        colorScheme: ColorScheme
    ) {
        let maximumVisibleToasts = max(1, maximumVisibleToasts)

        if self.edge != edge {
            self.edge = edge
        }
        if self.maximumVisibleToasts != maximumVisibleToasts {
            self.maximumVisibleToasts = maximumVisibleToasts
        }
        if self.colorScheme != colorScheme {
            self.colorScheme = colorScheme
        }
    }
}

private struct ToastStackOverlay: View {
    @ObservedObject var center: ToastCenter
    @ObservedObject var configuration: ToastStackConfiguration

    @State private var dragOffsets: [UUID: CGFloat] = [:]
    @State private var isContentPresented = false
    @State private var draggedToastID: UUID?

    private var alignment: Alignment {
        switch configuration.edge {
        case .top: .top
        case .bottom: .bottom
        }
    }

    private var transitionEdge: Edge {
        switch configuration.edge {
        case .top: .top
        case .bottom: .bottom
        }
    }

    private var scaleAnchor: UnitPoint {
        switch configuration.edge {
        case .top: .top
        case .bottom: .bottom
        }
    }

    private var visibleEntries: [ToastCenter.Entry] {
        guard isContentPresented else { return [] }
        return Array(center.entries.suffix(configuration.maximumVisibleToasts))
    }

    var body: some View {
        ZStack(alignment: alignment) {
            ForEach(Array(visibleEntries.enumerated()), id: \.element.id) { index, entry in
                let depth = visibleEntries.count - index - 1
                let isFront = depth == 0

                stackedCard(
                    entry: entry,
                    depth: depth,
                    index: index,
                    isFront: isFront
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .padding(20)
        .preferredColorScheme(configuration.colorScheme)
        .animation(stackedToastAnimation(), value: center.entries.map(\.id))
        .animation(stackedToastReflowAnimation(), value: configuration.edge)
        .animation(stackedToastReflowAnimation(), value: configuration.maximumVisibleToasts)
        .onChangeCompat(of: center.entries.last?.id) { frontToastID in
            if let draggedToastID, draggedToastID != frontToastID {
                resumeDraggedToastIfNeeded()
            }
        }
        .onChangeCompat(of: configuration.edge) { _ in
            resumeDraggedToastIfNeeded()
        }
        .onDisappear {
            resumeDraggedToastIfNeeded()
        }
        .task {
            guard !isContentPresented else { return }

            // The hosting controller is created after the first entry has already been added.
            // Schedule insertion on the next main run-loop turn after its empty root is mounted.
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    continuation.resume()
                }
            }
            guard !Task.isCancelled, !isContentPresented else { return }

            withAnimation(stackedToastAnimation()) {
                isContentPresented = true
            }
        }
        .task(id: center.entries.map(\.id)) {
            try? await Task.sleep(
                nanoseconds: UInt64(Constants.stackedToastAnimationDuration * 1_000_000_000)
            )
            guard !Task.isCancelled else { return }

            let liveToastIDs = Set(center.entries.map(\.id))
            dragOffsets = dragOffsets.filter { liveToastIDs.contains($0.key) }
        }
    }

    private func dragOffset(for id: UUID) -> CGFloat {
        dragOffsets[id, default: 0]
    }

    private func dragOpacity(for id: UUID) -> Double {
        Double(max(CGFloat(0.5), 1 - abs(dragOffset(for: id)) / 200))
    }

    private func stackedCard(
        entry: ToastCenter.Entry,
        depth: Int,
        index: Int,
        isFront: Bool
    ) -> some View {
        let scale = 1 - min(CGFloat(depth) * 0.045, 0.14)
        let opacity = max(0.72, 1 - Double(depth) * 0.12)

        return entry.content
            .scaleEffect(scale, anchor: scaleAnchor)
            .offset(y: stackOffset(for: depth) + dragOffset(for: entry.id))
            .opacity(isFront ? dragOpacity(for: entry.id) : opacity)
            .zIndex(Double(index))
            .allowsHitTesting(isFront)
            .gesture(dragGesture(for: entry.id))
            .toastEntryTransition(edge: transitionEdge)
            .animation(stackedToastReflowAnimation(), value: depth)
    }

    private func stackOffset(for depth: Int) -> CGFloat {
        let distance = CGFloat(depth) * 10
        switch configuration.edge {
        case .top: return distance
        case .bottom: return -distance
        }
    }

    private func dragGesture(for id: UUID) -> some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .local)
            .onChanged { value in
                if draggedToastID != id {
                    resumeDraggedToastIfNeeded()
                    draggedToastID = id
                    center.pauseDismissal(for: id)
                }

                switch configuration.edge {
                case .bottom:
                    dragOffsets[id] = max(0, value.translation.height)
                case .top:
                    dragOffsets[id] = min(0, value.translation.height)
                }
            }
            .onEnded { value in
                let shouldDismiss = configuration.edge == .bottom
                    ? value.translation.height > 30
                    : value.translation.height < -30

                if shouldDismiss {
                    draggedToastID = nil
                    center.dismiss(id)
                } else {
                    center.resumeDismissal(for: id)
                    draggedToastID = nil
                    withAnimation(stackedToastAnimation()) {
                        dragOffsets[id] = nil
                    }
                }
            }
    }

    private func resumeDraggedToastIfNeeded() {
        guard let draggedToastID else { return }
        center.resumeDismissal(for: draggedToastID)
        self.draggedToastID = nil
        withAnimation(stackedToastReflowAnimation()) {
            dragOffsets[draggedToastID] = nil
        }
    }
}
