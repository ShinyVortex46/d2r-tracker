import SwiftData
import SwiftUI

@main
struct D2R_TrackerApp: App {
    let container: ModelContainer
    @State private var mfSettings = MFSettings()

    init() {
        do {
            container = try ModelContainer(for: DiabloRun.self, RunType.self, DiabloSession.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        RunType.seedIfNeeded(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Runs", systemImage: "figure.run")
                    }
                StatsViewWrapper()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }
                SettingsView()
                    .tabItem {
                        Label("Options", systemImage: "gearshape")
                    }
            }
            .environment(mfSettings)
            .modelContainer(container)
        }
    }
}
