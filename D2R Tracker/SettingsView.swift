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
                    NavigationLink("Adjust Recommended MF Values") {
                        RecommendedMFView()
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Clear All Runs")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
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
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Changes affect the MF threshold icons on all runs.")
            }
        }
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
