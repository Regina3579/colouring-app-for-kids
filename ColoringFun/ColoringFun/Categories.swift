import SwiftUI

enum Categories {
    static let all: [Category] = [
        Category(id: "animals", name: "Animals", emoji: "🐾",
                 tint: Color(red: 1.0, green: 0.86, blue: 0.72), items: animalItems,
                 thumbnail: "cat_animals"),
        Category(id: "dinosaurs", name: "Dinosaurs", emoji: "🦕",
                 tint: Color(red: 0.78, green: 0.92, blue: 0.78), items: dinosaurItems,
                 thumbnail: "cat_dinosaurs"),
        Category(id: "birds", name: "Birds", emoji: "🐦",
                 tint: Color(red: 0.80, green: 0.92, blue: 0.98),
                 items: birdItems, thumbnail: "cat_birds"),
        Category(id: "fairy", name: "Fairy", emoji: "🧚",
                 tint: Color(red: 0.90, green: 0.84, blue: 1.0), items: fairyItems,
                 thumbnail: "cat_fairy"),
        Category(id: "unicorn", name: "Unicorn", emoji: "🦄",
                 tint: Color(red: 0.96, green: 0.84, blue: 1.0), items: unicornItems,
                 thumbnail: "cat_unicorn"),
        Category(id: "princess", name: "Princess", emoji: "👸",
                 tint: Color(red: 1.0, green: 0.82, blue: 0.90),
                 items: princessImageItems + PrincessPages.all.map { .vector($0) }),
        Category(id: "cars", name: "Cars", emoji: "🚗",
                 tint: Color(red: 0.82, green: 0.88, blue: 0.96), items: carItems,
                 thumbnail: "cat_cars"),
        Category(id: "transport", name: "Transport", emoji: "🚍",
                 tint: Color(red: 1.0, green: 0.88, blue: 0.74), items: transportItems,
                 thumbnail: "cat_transport"),
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

    // Fairy outline pictures (tap to flood-fill).
    private static let fairySpecs: [(String, String, String, Color)] = [
        ("fairy_flower", "Flower Fairy", "🧚", Color(red: 1.0, green: 0.84, blue: 0.90)),
        ("fairy_butterfly", "Butterfly Fairy", "🧚", Color(red: 0.86, green: 0.80, blue: 0.95)),
        ("fairy_rainbow", "Rainbow Fairy", "🧚", Color(red: 0.80, green: 0.90, blue: 1.0)),
        ("fairy_princess", "Princess Fairy", "🧚", Color(red: 1.0, green: 0.82, blue: 0.92)),
        ("fairy_garden", "Garden Fairy", "🧚", Color(red: 0.84, green: 0.94, blue: 0.84)),
        ("fairy_star", "Star Fairy", "🧚", Color(red: 0.86, green: 0.84, blue: 1.0)),
        ("fairy_ballerina", "Ballerina Fairy", "🧚", Color(red: 1.0, green: 0.82, blue: 0.90)),
        ("fairy_forest", "Woodland Fairy", "🧚", Color(red: 0.82, green: 0.92, blue: 0.80)),
        ("fairy_mermaid", "Mermaid Fairy", "🧚", Color(red: 0.78, green: 0.92, blue: 0.94)),
        ("fairy_winter", "Snow Fairy", "🧚", Color(red: 0.86, green: 0.92, blue: 1.0)),
    ]

    private static let fairyItems: [CategoryItem] = fairySpecs.map {
        .image(ImagePage(id: $0.0, title: $0.1, emoji: $0.2, imageName: $0.0, cardTint: $0.3))
    }

    // Unicorn outline pictures (tap to flood-fill).
    private static let unicornSpecs: [(String, String, String, Color)] = [
        ("unicorn_rainbow", "Rainbow Unicorn", "🦄", Color(red: 1.0, green: 0.85, blue: 0.92)),
        ("unicorn_princess", "Princess Unicorn", "🦄", Color(red: 0.95, green: 0.84, blue: 1.0)),
        ("unicorn_baby", "Baby Unicorn", "🦄", Color(red: 0.86, green: 0.92, blue: 1.0)),
        ("unicorn_pegacorn", "Pegacorn", "🦄", Color(red: 0.88, green: 0.90, blue: 1.0)),
        ("unicorn_flower", "Flower Unicorn", "🦄", Color(red: 1.0, green: 0.88, blue: 0.94)),
        ("unicorn_mermaid", "Mermaid Unicorn", "🦄", Color(red: 0.78, green: 0.94, blue: 0.96)),
        ("unicorn_galaxy", "Galaxy Unicorn", "🦄", Color(red: 0.84, green: 0.82, blue: 1.0)),
        ("unicorn_crystal", "Crystal Unicorn", "🦄", Color(red: 0.86, green: 0.96, blue: 0.98)),
        ("unicorn_snow", "Snow Unicorn", "🦄", Color(red: 0.88, green: 0.94, blue: 1.0)),
        ("unicorn_fairy", "Fairy Unicorn", "🦄", Color(red: 0.96, green: 0.86, blue: 1.0)),
    ]

    private static let unicornItems: [CategoryItem] = unicornSpecs.map {
        .image(ImagePage(id: $0.0, title: $0.1, emoji: $0.2, imageName: $0.0, cardTint: $0.3))
    }

    // Bird outline pictures (tap to flood-fill).
    private static let birdSpecs: [(String, String, String, Color)] = [
        ("bird_parrot", "Parrot", "🦜", Color(red: 0.80, green: 0.94, blue: 0.80)),
        ("bird_owl", "Owl", "🦉", Color(red: 0.90, green: 0.86, blue: 0.78)),
        ("bird_peacock", "Peacock", "🦚", Color(red: 0.74, green: 0.92, blue: 0.92)),
        ("bird_penguin", "Penguin", "🐧", Color(red: 0.82, green: 0.90, blue: 0.96)),
        ("bird_flamingo", "Flamingo", "🦩", Color(red: 1.0, green: 0.84, blue: 0.90)),
        ("bird_sparrow", "Sparrow", "🐦", Color(red: 0.92, green: 0.88, blue: 0.78)),
        ("bird_toucan", "Toucan", "🦜", Color(red: 0.84, green: 0.94, blue: 0.84)),
        ("bird_duck", "Duck", "🦆", Color(red: 1.0, green: 0.95, blue: 0.74)),
        ("bird_chicken", "Chicken", "🐔", Color(red: 1.0, green: 0.90, blue: 0.78)),
        ("bird_bluebird", "Bluebird", "🐦", Color(red: 0.80, green: 0.90, blue: 1.0)),
    ]

    private static let birdItems: [CategoryItem] = birdSpecs.map {
        .image(ImagePage(id: $0.0, title: $0.1, emoji: $0.2, imageName: $0.0, cardTint: $0.3))
    }

    // Car outline pictures (tap to flood-fill).
    private static let carSpecs: [(String, String, String, Color)] = [
        ("car_race", "Race Car", "🏎️", Color(red: 1.0, green: 0.84, blue: 0.80)),
        ("car_sports", "Sports Car", "🚗", Color(red: 1.0, green: 0.82, blue: 0.82)),
        ("car_monster", "Monster Truck", "🚚", Color(red: 0.84, green: 0.90, blue: 0.82)),
        ("car_police", "Police Car", "🚓", Color(red: 0.82, green: 0.88, blue: 0.98)),
        ("car_convertible", "Convertible", "🚗", Color(red: 1.0, green: 0.90, blue: 0.78)),
        ("car_beetle", "Beetle", "🚙", Color(red: 0.84, green: 0.92, blue: 0.84)),
        ("car_taxi", "Taxi", "🚕", Color(red: 1.0, green: 0.92, blue: 0.70)),
        ("car_jeep", "Jeep", "🚙", Color(red: 0.86, green: 0.86, blue: 0.78)),
        ("car_family", "Family Car", "🚐", Color(red: 0.84, green: 0.90, blue: 0.96)),
        ("car_electric", "Electric Car", "🔋", Color(red: 0.80, green: 0.94, blue: 0.84)),
    ]

    private static let carItems: [CategoryItem] = carSpecs.map {
        .image(ImagePage(id: $0.0, title: $0.1, emoji: $0.2, imageName: $0.0, cardTint: $0.3))
    }

    // Transport outline pictures (tap to flood-fill).
    private static let transportSpecs: [(String, String, String, Color)] = [
        ("tr_firetruck", "Fire Truck", "🚒", Color(red: 1.0, green: 0.80, blue: 0.78)),
        ("tr_icecream", "Ice Cream Truck", "🍦", Color(red: 1.0, green: 0.86, blue: 0.92)),
        ("tr_schoolbus", "School Bus", "🚌", Color(red: 1.0, green: 0.92, blue: 0.70)),
        ("tr_towtruck", "Tow Truck", "🛻", Color(red: 0.86, green: 0.90, blue: 0.80)),
        ("tr_dumptruck", "Dump Truck", "🚛", Color(red: 1.0, green: 0.88, blue: 0.72)),
        ("tr_train", "Train", "🚆", Color(red: 0.82, green: 0.90, blue: 0.96)),
        ("tr_rocket", "Rocket", "🚀", Color(red: 0.86, green: 0.84, blue: 0.98)),
        ("tr_tractor", "Tractor", "🚜", Color(red: 0.86, green: 0.92, blue: 0.78)),
        ("tr_sailboat", "Sailboat", "⛵", Color(red: 0.80, green: 0.92, blue: 0.98)),
        ("tr_ship", "Ship", "🚢", Color(red: 0.82, green: 0.90, blue: 0.96)),
    ]

    private static let transportItems: [CategoryItem] = transportSpecs.map {
        .image(ImagePage(id: $0.0, title: $0.1, emoji: $0.2, imageName: $0.0, cardTint: $0.3))
    }

    // Image-based princess pictures (original characters only).
    private static let princessImageSpecs: [(String, String, String, Color)] = [
        ("princess_mermaid", "Mermaid Princess", "🧜‍♀️", Color(red: 0.78, green: 0.92, blue: 0.96)),
    ]

    private static let princessImageItems: [CategoryItem] = princessImageSpecs.map {
        .image(ImagePage(id: $0.0, title: $0.1, emoji: $0.2, imageName: $0.0, cardTint: $0.3))
    }
}
