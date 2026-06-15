import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct ColoringFunApp: App {
    init() { Self.configureNavigationBar() }

    var body: some Scene {
        WindowGroup {
            GalleryView()
        }
    }

    /// Makes navigation titles bold, rounded and a friendly dark colour
    /// (they were rendering white/invisible on the light background).
    private static func configureNavigationBar() {
        let ink = UIColor(red: 0.32, green: 0.30, blue: 0.45, alpha: 1)

        func rounded(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            if let d = base.fontDescriptor.withDesign(.rounded) {
                return UIFont(descriptor: d, size: size)
            }
            return base
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: ink, .font: rounded(34, .heavy)]
        appearance.titleTextAttributes = [.foregroundColor: ink, .font: rounded(18, .bold)]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = ink
    }
}
