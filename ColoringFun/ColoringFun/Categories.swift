import SwiftUI

enum Categories {
    static let all: [Category] = [
        Category(id: "animals", name: "Animals", emoji: "🐾",
                 tint: Color(red: 1.0, green: 0.86, blue: 0.72), pages: AnimalPages.all),
        Category(id: "birds", name: "Birds", emoji: "🐦",
                 tint: Color(red: 0.80, green: 0.92, blue: 0.98), pages: BirdPages.all),
        Category(id: "fairy", name: "Fairy", emoji: "🧚",
                 tint: Color(red: 0.90, green: 0.84, blue: 1.0), pages: FairyPages.all),
        Category(id: "princess", name: "Princess", emoji: "👸",
                 tint: Color(red: 1.0, green: 0.82, blue: 0.90), pages: PrincessPages.all),
    ]
}
