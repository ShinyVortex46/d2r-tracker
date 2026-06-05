import Foundation
import SwiftData

@Model
class RunType {
    var name: String
    var defaultRecommendedMF: Int
    var sortOrder: Int

    init(name: String, defaultRecommendedMF: Int, sortOrder: Int = 0) {
        self.name = name
        self.defaultRecommendedMF = defaultRecommendedMF
        self.sortOrder = sortOrder
    }

    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<RunType>()
        guard let count = try? context.fetchCount(descriptor), count == 0 else { return }

        let defaults: [(String, Int)] = [
            ("Andariel", 250),
            ("Duriel", 200),
            ("Mephisto", 350),
            ("Diablo", 400),
            ("Baal", 400),
            ("Nihlathak", 300),
        ]

        for (index, (name, mf)) in defaults.enumerated() {
            context.insert(RunType(name: name, defaultRecommendedMF: mf, sortOrder: index))
        }
    }
}
