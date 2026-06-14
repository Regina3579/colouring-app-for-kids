import SwiftUI

/// Friendly colours used across the app's buttons.
enum Candy {
    static let blue   = Color(red: 0.36, green: 0.60, blue: 1.00)
    static let green  = Color(red: 0.32, green: 0.80, blue: 0.50)
    static let purple = Color(red: 0.66, green: 0.45, blue: 0.95)
    static let pink   = Color(red: 1.00, green: 0.49, blue: 0.73)
    static let orange = Color(red: 1.00, green: 0.62, blue: 0.25)
    static let teal   = Color(red: 0.20, green: 0.78, blue: 0.78)
    static let red    = Color(red: 1.00, green: 0.45, blue: 0.48)
    static let yellow = Color(red: 1.00, green: 0.80, blue: 0.25)
    static let ink    = Color(red: 0.32, green: 0.30, blue: 0.45)
}

extension View {
    /// Wraps an icon in a cute, glossy round button (for nav-bar actions).
    func cuteCircle(_ color: Color, size: CGFloat = 36) -> some View {
        self
            .font(.system(size: size * 0.46, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(color.gradient)
                    .overlay(
                        Circle().fill(.white.opacity(0.25))
                            .frame(width: size * 0.5, height: size * 0.5)
                            .offset(x: -size * 0.12, y: -size * 0.15)
                            .blur(radius: 1)
                    )
            )
            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
            .shadow(color: color.opacity(0.4), radius: 3, y: 2)
    }
}
