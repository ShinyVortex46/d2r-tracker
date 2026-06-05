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
                Section {
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
                } header: {
                    DiabloSectionHeader(title: "Overview")
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    if let runType = mostFarmedRunType {
                        HStack {
                            Text(runType)
                                .font(Theme.cardTitle)
                                .foregroundStyle(Theme.C.textParchment)
                            Spacer()
                            Text("\(runs.filter { $0.runTypeName == runType }.count) runs")
                                .foregroundStyle(Theme.C.textMuted)
                        }
                    } else {
                        Text("No runs yet")
                            .foregroundStyle(Theme.C.textMuted)
                    }
                } header: {
                    DiabloSectionHeader(title: "Most Farmed")
                }
                .listRowBackground(Theme.C.surfaceCard)
                .listRowSeparatorTint(Theme.C.borderStone)

                Section {
                    Chart(topRunTypes, id: \.self) { runType in
                        BarMark(
                            x: .value("Run Type", runType),
                            y: .value("Runs", runs.filter { $0.runTypeName == runType }.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.C.goldPrimary, Theme.C.goldBright],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Theme.C.textMuted)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(Theme.C.borderStone.opacity(0.5))
                            AxisValueLabel()
                                .foregroundStyle(Theme.C.textMuted)
                        }
                    }
                    .chartBackground { _ in Theme.C.surfaceCard }
                    .frame(height: 180)
                    .padding(.vertical, 4)
                } header: {
                    DiabloSectionHeader(title: "Runs by Type")
                }
                .listRowBackground(Theme.C.surfaceCard)
                .listRowSeparatorTint(Theme.C.borderStone)

                Section {
                    ForEach(topRunTypes, id: \.self) { runType in
                        let count = runs.filter { $0.runTypeName == runType }.count
                        HStack {
                            Text(runType)
                                .font(Theme.cardTitle)
                                .foregroundStyle(Theme.C.textParchment)
                            Spacer()
                            Text("\(count) runs")
                                .foregroundStyle(Theme.C.textMuted)
                        }
                    }
                } header: {
                    DiabloSectionHeader(title: "By Run Type")
                }
                .listRowBackground(Theme.C.surfaceCard)
                .listRowSeparatorTint(Theme.C.borderStone)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.C.backgroundDeep)
            .navigationTitle("Stats")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(Theme.sectionHeader)
                .foregroundStyle(Theme.C.textMuted)
                .tracking(1.2)
            Text(value)
                .font(Theme.statValue)
                .foregroundStyle(Theme.C.goldBright)
                .shadow(color: Theme.C.goldPrimary.opacity(0.3), radius: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .stoneCard()
    }
}
