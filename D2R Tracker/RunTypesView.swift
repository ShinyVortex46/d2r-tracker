import SwiftData
import SwiftUI

struct RunTypesView: View {
    @Query(sort: \RunType.sortOrder) var runTypes: [RunType]
    @Query var runs: [DiabloRun]
    @Environment(\.modelContext) var modelContext

    @State private var showingAddAlert = false
    @State private var newTypeName = ""
    @State private var deletionError: String? = nil

    var body: some View {
        List {
            ForEach(runTypes) { runType in
                Text(runType.name)
            }
            .onDelete(perform: attemptDelete)
        }
        .navigationTitle("Run Types")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newTypeName = ""
                    showingAddAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Run Type", isPresented: $showingAddAlert) {
            TextField("Name", text: $newTypeName)
            Button("Add") {
                let trimmed = newTypeName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                let maxOrder = runTypes.map(\.sortOrder).max() ?? -1
                modelContext.insert(RunType(name: trimmed, defaultRecommendedMF: 0, sortOrder: maxOrder + 1))
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Cannot Delete", isPresented: Binding(
            get: { deletionError != nil },
            set: { if !$0 { deletionError = nil } }
        )) {
            Button("OK", role: .cancel) { deletionError = nil }
        } message: {
            Text(deletionError ?? "")
        }
    }

    private func attemptDelete(_ indexSet: IndexSet) {
        for index in indexSet {
            let runType = runTypes[index]
            let usedByRuns = runs.contains { $0.runTypeName == runType.name }
            if usedByRuns {
                deletionError = "\"\(runType.name)\" is used by existing runs and cannot be deleted."
            } else {
                modelContext.delete(runType)
            }
        }
    }
}
