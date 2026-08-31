# LivsyToast

A lightweight SwiftUI toast presenter that displays transient messages above your UI using a transparent, pass-through overlay window. It supports showing from the top or bottom edge, auto-dismiss after a configurable duration, and interactive drag-to-dismiss.

https://github.com/user-attachments/assets/5cb1094b-2e1c-41a2-a0b0-85fef6fea065

https://github.com/user-attachments/assets/197de35e-05de-4fc2-8690-d2a1bc8263b3

## Features

- Present any custom SwiftUI view as a toast
- Convenience overload for text-based toasts
- Appears from the top or bottom edge
- Optional auto-dismiss with configurable duration
- Drag-to-dismiss in the direction of presentation
- Optional onDismiss callback when the toast fully disappears
- Stacked presentation with independent auto-dismiss timers
- Overlay window that passes touches through to underlying content where appropriate

## Requirements

- iOS 15+

## Installation

Install via Swift Package Manager using the repository URL:

```
https://github.com/Livsy90/LivsyToast.git
```

## Usage

LivsyToast provides two presentation APIs:

- `toast(...)` presents one toast controlled by a `Binding<Bool>`.
- `toastStack(center:...)` presents multiple toasts managed by a `ToastCenter`.

### Single toast

Use the text convenience overload when the default appearance is sufficient:

```swift
import SwiftUI
import LivsyToast

struct TextToastDemo: View {
    @State private var isToastPresented = false

    var body: some View {
        Button("Show toast") {
            isToastPresented = true
        }
        .toast(
            isPresented: $isToastPresented,
            message: "Saved successfully",
            duration: 2,
            edge: .top,
            onDismiss: {
                print("Toast dismissed")
            }
        )
    }
}
```

The content overload accepts any SwiftUI view through `@ViewBuilder`:

```swift
struct CustomToastDemo: View {
    @State private var isToastPresented = false

    var body: some View {
        Button("Show toast") {
            isToastPresented = true
        }
        .toast(
            isPresented: $isToastPresented,
            duration: 4,
            edge: .bottom
        ) {
            Label("Upload completed", systemImage: "checkmark.circle.fill")
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(20)
        }
    }
}
```

Set `duration` to `nil` or a value less than or equal to zero to disable automatic dismissal.
The binding can then be set to `false` to dismiss the toast manually.

### Stacked toasts

Use `ToastCenter` when multiple events can produce toasts. The center owns the internal
collection, stable identifiers, and dismissal tasks; callers do not need to maintain an array.
Keep the center alive for the lifetime of the view hierarchy that presents the stack.

```swift
import SwiftUI
import LivsyToast

struct StackedToastDemo: View {
    @StateObject private var toasts = ToastCenter()

    var body: some View {
        VStack(spacing: 16) {
            Button("Show text toast") {
                toasts.show("Saved successfully")
            }

            Button("Show custom toast") {
                toasts.show(duration: 6) {
                    Label("Upload completed", systemImage: "checkmark.circle.fill")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            Button("Dismiss all") {
                toasts.dismissAll()
            }
        }
        .toastStack(
            center: toasts,
            edge: .bottom,
            maximumVisibleToasts: 3
        )
    }
}
```

New toasts are placed at the front of the stack. Only the front toast is interactive and can be
dragged toward its presentation edge. Older toasts move forward as newer toasts are dismissed.
Every toast keeps its own auto-dismiss timer, including items beyond `maximumVisibleToasts`.

### Manual dismissal and callbacks

Both `ToastCenter.show` overloads return a `UUID`. Pass it to `dismiss(_:)` to remove a specific
toast. Use `duration: nil` when the toast should remain visible until explicitly dismissed.

```swift
let toastID = toasts.show(
    "Uploading…",
    duration: nil,
    onDismiss: {
        print("Upload toast dismissed")
    }
)

toasts.dismiss(toastID)
toasts.dismissAll()
```

`onDismiss` runs after the removal animation finishes, regardless of whether dismissal was
automatic, manual, or caused by a drag gesture.

### NavigationStack

Toasts are presented in a separate pass-through overlay window, so they are not tied to a
specific navigation destination. Attach the modifier outside `NavigationStack` and keep its
state or `ToastCenter` at that level:

```swift
struct NavigationToastDemo: View {
    @StateObject private var toasts = ToastCenter()

    var body: some View {
        NavigationStack {
            NavigationLink("Open details") {
                Button("Show toast over details") {
                    toasts.show("Toast from the details screen")
                }
            }
            .navigationTitle("Root")
        }
        .toastStack(center: toasts, edge: .bottom)
    }
}
```

The toast remains visible while pushing or popping destinations. `NavigationStack` itself
requires iOS 16+, while LivsyToast continues to support iOS 15+.

## API overview

### `View.toast`

```swift
func toast<T: View>(
    isPresented: Binding<Bool>,
    duration: TimeInterval? = 4,
    edge: VerticalEdge = .bottom,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> T
) -> some View

func toast(
    isPresented: Binding<Bool>,
    message: String,
    duration: TimeInterval? = 4,
    edge: VerticalEdge = .bottom,
    onDismiss: (() -> Void)? = nil
) -> some View
```

### `View.toastStack`

```swift
func toastStack(
    center: ToastCenter,
    edge: VerticalEdge = .bottom,
    maximumVisibleToasts: Int = 3
) -> some View
```

`maximumVisibleToasts` is clamped to at least `1`.

### `ToastCenter`

```swift
@discardableResult
func show(
    _ message: String,
    duration: TimeInterval? = 4,
    onDismiss: (() -> Void)? = nil
) -> UUID

@discardableResult
func show<Content: View>(
    duration: TimeInterval? = 4,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content
) -> UUID

func dismiss(_ id: UUID)
func dismissAll()
```
