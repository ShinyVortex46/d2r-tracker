import Foundation
import SwiftData

// MARK: - DiabloRun

// drops is stored as a JSON-encoded String (column name "drops" unchanged from v1).
// No schema migration needed — the column type stays VARCHAR.
// Old plain-string values ("Nothing", "Vex Rune") are decoded lazily in the getter.
@Model
class DiabloRun {
    @Attribute(originalName: "bossRawValue") var runTypeName: String
    var duration: Int
    var magicFind: Int
    @Attribute(originalName: "drops") var dropsRaw: String
    var date: Date
    var startDate: Date?
    var session: DiabloSession?

    init(runTypeName: String, duration: Int, magicFind: Int, drops: [String] = [],
         startDate: Date? = nil, date: Date = .now) {
        self.runTypeName = runTypeName
        self.duration = duration
        self.magicFind = magicFind
        self.dropsRaw = (try? String(data: JSONEncoder().encode(drops), encoding: .utf8)) ?? "[]"
        self.startDate = startDate
        self.date = date
        self.session = nil
    }

    var drops: [String] {
        get {
            if let data = dropsRaw.data(using: .utf8),
               let decoded = try? JSONDecoder().decode([String].self, from: data) {
                return decoded
            }
            // Legacy plain-string format from before the picker was added
            let trimmed = dropsRaw.trimmingCharacters(in: .whitespaces)
            return (trimmed.isEmpty || trimmed == "Nothing") ? [] : [trimmed]
        }
        set {
            dropsRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var durationInMinutes: Double { Double(duration) / 60.0 }
}
