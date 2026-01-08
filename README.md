# LivsyToast

A lightweight SwiftUI toast presenter that displays transient messages above your UI using a transparent, pass-through overlay window. It supports showing from the top or bottom edge, auto-dismiss after a configurable duration, and interactive drag-to-dismiss.

## Features
- Present any custom SwiftUI view as a toast
- Convenience overload for text-based toasts
- Appears from the top or bottom edge
- Optional auto-dismiss with configurable duration
- Drag-to-dismiss in the direction of presentation
- Optional onDismiss callback when the toast fully disappears
- Overlay window that passes touches through to underlying content where appropriate

## Installation
Install via Swift Package Manager using the repository URL:

```
https://github.com/Livsy90/LivsyToast.git
```

## Usage
Use the `toast` view modifier on any view hierarchy. Control visibility with a `@State` binding. You can either provide a custom view or a simple message string.

### Example (custom content, generic overload)
```swift
import SwiftUI

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
```
