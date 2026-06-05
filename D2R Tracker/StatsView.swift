import Charts
import SwiftData
import SwiftUI

struct StatsViewWrapper: View {
    @Query var runs: [DiabloRun]

    var body: some View {
        StatsView(runs: runs)
    }
}

struct StatsView: View {
    var runs: [DiabloRun]

    var totalRuns: Int { runs.count }

    var averageMF: Int {
        guard !runs.isEmpty else { return 0 }
        return runs.map { $0.magicFind }.reduce(0, +) / runs.count
    }

    var averageDuration: Double {
        guard !runs.isEmpty else { return 0 }
        return Double(runs.map { $0.duration }.reduce(0, +)) / Double(runs.count) / 60
    }

    var totalTime: Double {
        Double(runs.map { $0.duration }.reduce(0, +)) / 60.0
    }

    var mostFarmedRunType: String? {
        guard !runs.isEmpty else { return nil }
        let grouped = Dictionary(grouping: runs, by: \.runTypeName)
        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }

    var topRunTypes: [String] {
        let grouped = Dictionary(grouping: runs, by: \.runTypeName)
        return grouped
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { $0.key }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    HStack {
                        StatCard(title: "Total Runs", value: "\(totalRuns)")
                        StatCard(title: "Average MF", value: "\(averageMF)%")
                    }
                    HStack {
                        StatCard(
                            title: "Average Duration",
                            value: String(format: "%.1f min", averageDuration)
                        )
                        StatCard(
                            title: "Total Time",
                            value: String(format: "%.1f min", totalTime)
                        )
                    }
                }
                Section("Most farmed run type") {
                    if let runType = mostFarmedRunType {
                        HStack {
                            Text(runType)
                                .font(.headline)
                            Spacer()
                            Text("\(runs.filter { $0.runTypeName == runType }.count) runs")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No runs yet")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Runs by Type") {
                    Chart(topRunTypes, id: \.self) { runType in
                        BarMark(
                            x: .value("Run Type", runType),
                            y: .value("Runs", runs.filter { $0.runTypeName == runType }.count)
                        )
                    }
                    .frame(height: 180)
                }
                Section("By Run Type") {
                    ForEach(topRunTypes, id: \.self) { runType in
                        let count = runs.filter { $0.runTypeName == runType }.count
                        HStack {
                            Text(runType)
                            Spacer()
                            Text("\(count) runs")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
