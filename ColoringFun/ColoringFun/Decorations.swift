import SwiftUI

/// A simple upward triangle (used for the crayon tip).
struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A cute single crayon (tip + body + paper band).
struct CrayonView: View {
    let color: Color
    var width: CGFloat = 22
    var height: CGFloat = 78

    var body: some View {
        VStack(spacing: -2) {
            Triangle()
                .fill(color.gradient)
                .frame(width: width * 0.7, height: height * 0.16)
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: width * 0.28)
                    .fill(color.gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: width * 0.28)
                            .fill(.white.opacity(0.18))
                            .frame(width: width * 0.32)
                            .offset(x: -width * 0.22)
                    )
                VStack(spacing: 2) {
                    Rectangle().fill(.white.opacity(0.9)).frame(height: height * 0.14)
                    Rectangle().fill(.white.opacity(0.5)).frame(height: 2)
                }
                .padding(.top, height * 0.12)
            }
            .frame(width: width, height: height * 0.84)
            .clipShape(RoundedRectangle(cornerRadius: width * 0.28))
        }
        .frame(width: width, height: height)
        .shadow(color: color.opacity(0.35), radius: 2, y: 2)
    }
}

/// A fun row of colourful crayons (a "crayon box").
struct CrayonRow: View {
    var colors: [Color] = [Candy.red, Candy.orange, Candy.yellow, Candy.green,
                           Candy.teal, Candy.blue, Candy.purple, Candy.pink]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(colors.enumerated()), id: \.offset) { i, c in
                CrayonView(color: c)
                    .rotationEffect(.degrees(Double(i - colors.count / 2) * 4))
                    .offset(y: abs(Double(i) - Double(colors.count - 1) / 2) * 2)
            }
        }
    }
}
