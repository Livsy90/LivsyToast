import SwiftUI

@MainActor
final class OverlayWindow {
    private var window: UIWindow?

    var isVisible: Bool { window != nil }
    
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
