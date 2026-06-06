import CoreText
import SwiftData
import SwiftUI

@main
struct D2R_TrackerApp: App {
    let container: ModelContainer
    @State private var mfSettings = MFSettings()

    init() {
        do {
            container = try ModelContainer(for: DiabloRun.self, DiabloSession.self, RunType.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        RunType.seedIfNeeded(in: container.mainContext)
        registerFonts()
        setupAppearance()
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
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Font Registration

    private func registerFonts() {
        for name in ["films.EXH_____.ttf", "films.EXL_____.ttf"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
                assertionFailure("[Theme] Missing bundled font: \(name)")
                continue
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if let e = error { print("[Theme] Registration error: \(e.takeUnretainedValue())") }
        }
    }

    // MARK: - UIKit Appearance

    private func setupAppearance() {
        let deepBg = UIColor(Theme.C.backgroundDeep)
        let cardBg = UIColor(Theme.C.surfaceCard)
        let gold   = UIColor(Theme.C.goldPrimary)
        let stone  = UIColor(Theme.C.borderStone)
        let muted  = UIColor(Theme.C.textMuted)

        let titleFont = UIFont(name: "ExocetHeavy", size: 17)
            ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        let lgFont = UIFont(name: "ExocetHeavy", size: 28)
            ?? UIFont.systemFont(ofSize: 28, weight: .bold)

        // Navigation Bar
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = deepBg
        nav.shadowColor = stone
        nav.titleTextAttributes = [.foregroundColor: gold, .font: titleFont]
        nav.largeTitleTextAttributes = [.foregroundColor: gold, .font: lgFont]

        let backItem = UIBarButtonItemAppearance()
        backItem.normal.titleTextAttributes = [.foregroundColor: gold]
        nav.backButtonAppearance = backItem

        UINavigationBar.appearance().standardAppearance   = nav
        UINavigationBar.appearance().compactAppearance    = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor            = gold

        // Tab Bar
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = cardBg
        tab.shadowColor = UIColor(Theme.C.goldPrimary).withAlphaComponent(0.35)

        let selectedLayouts = [
            tab.stackedLayoutAppearance.selected,
            tab.inlineLayoutAppearance.selected,
            tab.compactInlineLayoutAppearance.selected,
        ]
        for state in selectedLayouts {
            state.iconColor = gold
            state.titleTextAttributes = [.foregroundColor: gold]
        }

        let normalLayouts = [
            tab.stackedLayoutAppearance.normal,
            tab.inlineLayoutAppearance.normal,
            tab.compactInlineLayoutAppearance.normal,
        ]
        for state in normalLayouts {
            state.iconColor = muted
            state.titleTextAttributes = [.foregroundColor: muted]
        }

        UITabBar.appearance().standardAppearance   = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        // List / Table backgrounds
        UITableView.appearance().backgroundColor          = deepBg
        UITableViewCell.appearance().backgroundColor      = .clear
    }
}
