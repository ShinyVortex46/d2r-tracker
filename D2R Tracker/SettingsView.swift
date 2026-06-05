import SwiftData
import SwiftUI

@Observable
class MFSettings {
    private var cache: [String: Int] = [:]

    func effectiveMF(for name: String, defaultMF: Int) -> Int {
        if let cached = cache[name] { return cached }
        let stored = UserDefaults.standard.integer(forKey: "mf_\(name)")
        let value = stored > 0 ? stored : defaultMF
        cache[name] = value
        return value
    }

    func save(_ mf: Int, for name: String) {
        cache[name] = mf
        UserDefaults.standard.set(mf, forKey: "mf_\(name)")
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) var modelContext
    @Query var runs: [DiabloRun]
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Edit Run Types") {
                        RunTypesView()
                    }
                    .foregroundStyle(Theme.C.textParchment)
                    NavigationLink("Adjust Recommended MF Values") {
                        RecommendedMFView()
                    }
                    .foregroundStyle(Theme.C.textParchment)
                } header: {
                    DiabloSectionHeader(title: "Configuration")
                }
                .listRowBackground(Theme.C.surfaceCard)
                .listRowSeparatorTint(Theme.C.borderStone)

                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Theme.C.bloodRedBright)
                            Text("Clear All Runs")
                                .font(Theme.cardTitle)
                                .foregroundStyle(Theme.C.bloodRedBright)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(
                    ZStack {
                        Theme.C.bloodRed.opacity(0.15)
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.C.bloodRed.opacity(0.5), lineWidth: 1)
                    }
                )
            }
            .scrollContentBackground(.hidden)
            .background(Theme.C.backgroundDeep)
            .navigationTitle("Options")
            .confirmationDialog(
                "Clear All Runs?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete \(runs.count) Run\(runs.count == 1 ? "" : "s")", role: .destructive) {
                    for run in runs {
                        modelContext.delete(run)
                    }
                }
            } message: {
                Text("This will permanently delete all recorded runs. This cannot be undone.")
            }
        }
    }
}

struct RecommendedMFView: View {
    @Environment(MFSettings.self) var mfSettings
    @Environment(\.dismiss) var dismiss
    @Query(sort: \RunType.sortOrder) var runTypes: [RunType]
    @State private var editedMF: [String: String] = [:]

    var body: some View {
        List {
            Section {
                ForEach(runTypes) { rt in
                    HStack {
                        Text(rt.name)
                            .font(Theme.cardTitle)
                            .foregroundStyle(Theme.C.textParchment)
                        Spacer()
                        TextField(
                            "\(rt.defaultRecommendedMF > 0 ? rt.defaultRecommendedMF : 0)",
                            text: Binding(
                                get: { editedMF[rt.name] ?? "" },
                                set: { editedMF[rt.name] = $0 }
                            )
                        )
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .foregroundStyle(Theme.C.goldBright)
                        Text("%")
                            .foregroundStyle(Theme.C.textMuted)
                    }
                }
            } footer: {
                Text("Changes affect the MF threshold icons on all runs.")
                    .foregroundStyle(Theme.C.textMuted)
            }
            .listRowBackground(Theme.C.surfaceCard)
            .listRowSeparatorTint(Theme.C.borderStone)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.C.backgroundDeep)
        .navigationTitle("Recommended MF")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    for rt in runTypes {
                        if let text = editedMF[rt.name], let value = Int(text), value > 0 {
                            mfSettings.save(value, for: rt.name)
                        }
                    }
                    dismiss()
                }
            }
        }
        .onAppear {
            for rt in runTypes {
                editedMF[rt.name] = String(
                    mfSettings.effectiveMF(for: rt.name, defaultMF: rt.defaultRecommendedMF)
                )
            }
        }
    }
}
