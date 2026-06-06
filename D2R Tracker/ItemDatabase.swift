import Foundation

enum ItemCategory: String, CaseIterable {
    case rune    = "Rune"
    case unique  = "Unique"
    case setItem = "Set Item"
    case gem     = "Gem"
}

struct GameItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: ItemCategory
    let rarity: Int
}

enum ItemDatabase {
    static let runes: [GameItem] = {
        let names = [
            "El", "Eld", "Tir", "Nef", "Eth", "Ith", "Tal", "Ral", "Ort", "Thul",
            "Amn", "Sol", "Shael", "Dol", "Hel", "Io", "Lum", "Ko", "Fal", "Lem",
            "Pul", "Um", "Mal", "Ist", "Gul", "Vex", "Ohm", "Lo", "Sur", "Ber",
            "Jah", "Cham", "Zod"
        ]
        return names.enumerated().map {
            GameItem(id: UUID(), name: $0.element, category: .rune, rarity: $0.offset + 1)
        }
    }()

    static var all: [GameItem] { runes }
}
