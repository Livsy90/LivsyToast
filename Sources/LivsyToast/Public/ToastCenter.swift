import SwiftUI

/// Owns the toasts presented by a ``View/toastStack(center:edge:maximumVisibleToasts:)`` modifier.
///
/// Keep one center alive for as long as the view hierarchy that presents the stack. Calling
/// ``show(_:duration:onDismiss:)`` or ``show(duration:onDismiss:content:)`` appends a toast to
/// the stack; callers do not need to manage an array or dismissal timers themselves.
@MainActor
public final class ToastCenter: ObservableObject {
    struct Entry: Identifiable {
        let id: UUID
        let duration: TimeInterval?
        let content: AnyView
        let onDismiss: (() -> Void)?
    }

    @Published private(set) var entries: [Entry] = []
    private var dismissalTasks: [UUID: Task<Void, Never>] = [:]

    public init() {}

    /// Appends a custom toast to the stack.
    ///
    /// - Returns: An identifier that can be passed to ``dismiss(_:)``.
    @discardableResult
    public func show<Content: View>(
        duration: TimeInterval? = 4,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> UUID {
        let id = UUID()
        let entry = Entry(
            id: id,
            duration: duration,
            content: AnyView(content()),
            onDismiss: onDismiss
        )

        entries.append(entry)
        scheduleDismissal(for: entry)
        return id
    }

    /// Appends a standard text toast to the stack.
    ///
    /// - Returns: An identifier that can be passed to ``dismiss(_:)``.
    @discardableResult
    public func show(
        _ message: String,
        duration: TimeInterval? = 4,
        onDismiss: (() -> Void)? = nil
    ) -> UUID {
        show(duration: duration, onDismiss: onDismiss) {
            Text(message)
                .font(.body)
                .fontWeight(.medium)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(20)
                .stackedToastBackground()
                .contentShape(Rectangle())
        }
    }

    /// Dismisses a specific toast if it is still in the stack.
    public func dismiss(_ id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let entry = entries.remove(at: index)
        dismissalTasks[id]?.cancel()
        dismissalTasks[id] = nil

        guard let onDismiss = entry.onDismiss else { return }
        Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: UInt64(Constants.stackedToastAnimationDuration * 1_000_000_000)
            )
            guard !Task.isCancelled else { return }
            onDismiss()
        }
    }

    /// Dismisses every toast currently in the stack.
    public func dismissAll() {
        let ids = entries.map(\.id)
        ids.forEach(dismiss)
    }

    func pauseDismissal(for id: UUID) {
        dismissalTasks[id]?.cancel()
        dismissalTasks[id] = nil
    }

    func resumeDismissal(for id: UUID) {
        guard let entry = entries.first(where: { $0.id == id }) else { return }
        scheduleDismissal(for: entry)
    }

    private func scheduleDismissal(for entry: Entry) {
        guard let duration = entry.duration, duration > 0 else { return }
        dismissalTasks[entry.id]?.cancel()

        let nanoseconds = UInt64(min(duration, TimeInterval(UInt64.max) / 1_000_000_000) * 1_000_000_000)
        dismissalTasks[entry.id] = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.dismiss(entry.id)
        }
    }
}
