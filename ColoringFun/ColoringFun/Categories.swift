import SwiftUI

enum Categories {
    static let all: [Category] = [
        Category(id: "animals", name: "Animals", emoji: "🐾",
                 tint: Color(red: 1.0, green: 0.86, blue: 0.72), items: animalItems),
        Category(id: "dinosaurs", name: "Dinosaurs", emoji: "🦕",
                 tint: Color(red: 0.78, green: 0.92, blue: 0.78), items: dinosaurItems),
        Category(id: "birds", name: "Birds", emoji: "🐦",
                 tint: Color(red: 0.80, green: 0.92, blue: 0.98),
                 items: BirdPages.all.map { .vector($0) }),
        Category(id: "fairy", name: "Fairy", emoji: "🧚",
                 tint: Color(red: 0.90, green: 0.84, blue: 1.0),
                 items: FairyPages.all.map { .vector($0) }),
        Category(id: "princess", name: "Princess", emoji: "👸",
                 tint: Color(red: 1.0, green: 0.82, blue: 0.90),
                 items: PrincessPages.all.map { .vector($0) }),
    ]

    // Real outline-image animals (tap to flood-fill).
    private static let animalSpecs: [(String, String, String, Color)] = [
        ("lion", "Lion", "🦁", Color(red: 1.0, green: 0.86, blue: 0.62)),
        ("elephant", "Elephant", "🐘", Color(red: 0.84, green: 0.88, blue: 0.92)),
        ("rabbit", "Rabbit", "🐰", Color(red: 0.92, green: 0.88, blue: 1.0)),
        ("tiger", "Tiger", "🐯", Color(red: 1.0, green: 0.84, blue: 0.62)),
        ("giraffe", "Giraffe", "🦒", Color(red: 1.0, green: 0.90, blue: 0.66)),
        ("monkey", "Monkey", "🐵", Color(red: 0.92, green: 0.82, blue: 0.70)),
        ("panda", "Panda", "🐼", Color(red: 0.90, green: 0.90, blue: 0.92)),
        ("fox", "Fox", "🦊", Color(red: 1.0, green: 0.84, blue: 0.70)),
        ("dog", "Puppy", "🐶", Color(red: 1.0, green: 0.88, blue: 0.74)),
        ("cat", "Kitten", "🐱", Color(red: 1.0, green: 0.80, blue: 0.88)),
    ]

    private static let animalItems: [CategoryItem] = animalSpecs.map {
        .image(ImagePage(id: $0.0, title: $0.1, emoji: $0.2, imageName: $0.0, cardTint: $0.3))
    }

    // Dinosaur outline pictures (tap to flood-fill).
    private static let dinosaurSpecs: [(String, String, String, Color)] = [
        ("trex", "T-Rex", "🦖", Color(red: 0.94, green: 0.84, blue: 0.74)),
        ("triceratops", "Triceratops", "🦕", Color(red: 0.80, green: 0.92, blue: 0.80)),
        ("stegosaurus", "Stegosaurus", "🦕", Color(red: 0.86, green: 0.92, blue: 0.74)),
        ("brachiosaurus", "Brachiosaurus", "🦕", Color(red: 0.82, green: 0.90, blue: 0.82)),
        ("ankylosaurus", "Ankylosaurus", "🦕", Color(red: 0.90, green: 0.88, blue: 0.74)),
        ("brontosaurus", "Diplodocus", "🦕", Color(red: 0.78, green: 0.90, blue: 0.90)),
        ("parasaurolophus", "Parasaurolophus", "🦕", Color(red: 0.88, green: 0.90, blue: 0.78)),
        ("velociraptor", "Velociraptor", "🦖", Color(red: 0.92, green: 0.86, blue: 0.76)),
        ("spinosaurus", "Spinosaurus", "🦖", Color(red: 0.80, green: 0.88, blue: 0.92)),
        ("pterodactyl", "Pteranodon", "🦖", Color(red: 0.84, green: 0.90, blue: 0.86)),
    ]

    private static let dinosaurItems: [CategoryItem] = dinosaurSpecs.map {
        .image(ImagePage(id: $0.0, title: $0.1, emoji: $0.2, imageName: $0.0, cardTint: $0.3))
    }
}
