import SwiftUI

extension View {
    @ViewBuilder
    func toastEntryTransition(edge: Edge) -> some View {
        if #available(iOS 17.0, *) {
            transition(.move(edge: edge).combined(with: .blurReplace))
        } else {
            transition(.move(edge: edge).combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    func onChangeCompat<V: Equatable>(
        of value: V,
        perform action: @escaping (V) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value, perform: action)
        }
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
    
    @ViewBuilder
    func stackedToastBackground() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 33))
        } else {
            background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 33))
        }
    }
}
