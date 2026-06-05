import SwiftData
import SwiftUI

// MARK: - Enums

enum SortOption: String, CaseIterable {
    case date = "Date"
    case duration = "Duration"
    case magicFind = "Magic Find"
}

enum SessionSortOption: String, CaseIterable {
    case date = "Date"
    case runCount = "Number of Runs"
}

// MARK: - Models

@Model
class DiabloRun {
    @Attribute(originalName: "bossRawValue") var runTypeName: String
    var duration: Int
    var magicFind: Int
    var drops: String
    var date: Date
    var startDate: Date?
    var session: DiabloSession?

    init(runTypeName: String, duration: Int, magicFind: Int, drops: String, startDate: Date? = nil, date: Date = .now) {
        self.runTypeName = runTypeName
        self.duration = duration
        self.magicFind = magicFind
        self.drops = drops
        self.startDate = startDate
        self.date = date
        self.session = nil
    }

    var durationInMinutes: Double { Double(duration) / 60.0 }
}

@Model
class DiabloSession {
    var name: String
    var runTypeName: String
    var createdDate: Date
    var startDate: Date?
    var endDate: Date?
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var runs: [DiabloRun] = []

    init(name: String, runTypeName: String) {
        self.name = name
        self.runTypeName = runTypeName
        self.createdDate = Date()
        self.startDate = nil
        self.endDate = nil
        self.isActive = true
    }

    var duration: Int {
        guard let s = startDate, let e = endDate else { return 0 }
        return Int(e.timeIntervalSince(s))
    }
}

// MARK: - Helpers

func makeSessionName(runTypeName: String, in context: ModelContext) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "dd/MM/yyyy"
    let dateStr = fmt.string(from: Date())
    let base = "\(runTypeName) session - \(dateStr)"
    let all = (try? context.fetch(FetchDescriptor<DiabloSession>())) ?? []
    guard all.contains(where: { $0.name == base }) else { return base }
    var i = 2
    while all.contains(where: { $0.name == "\(runTypeName) session \(i) - \(dateStr)" }) { i += 1 }
    return "\(runTypeName) session \(i) - \(dateStr)"
}

// MARK: - ContentView (Sessions list)

struct ContentView: View {
    @Query(sort: \DiabloSession.createdDate, order: .reverse) var sessions: [DiabloSession]
    @Query(filter: #Predicate<DiabloSession> { $0.isActive == true }) var activeSessions: [DiabloSession]
    @Environment(\.modelContext) var modelContext

    @State var sessionSortOption: SessionSortOption = .date
    @State var sortAscending: Bool = false
    @State var showSortSheet: Bool = false
    @State var showingAddRun: Bool = false
    @State var lastRunType: String = "Andariel"
    @State var lastMF: Int = 0

    var sortedSessions: [DiabloSession] {
        switch sessionSortOption {
        case .date:
            return sortAscending
                ? sessions.sorted { $0.createdDate < $1.createdDate }
                : sessions.sorted { $0.createdDate > $1.createdDate }
        case .runCount:
            return sortAscending
                ? sessions.sorted { $0.runs.count < $1.runs.count }
                : sessions.sorted { $0.runs.count > $1.runs.count }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedSessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .center) {
                                Text(session.name)
                                    .font(Theme.cardTitle)
                                    .foregroundStyle(Theme.C.textParchment)
                                Spacer()
                                if session.isActive {
                                    Text("ACTIVE")
                                        .font(Theme.badge)
                                        .foregroundStyle(Theme.C.bloodRedBright)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Theme.C.bloodRed.opacity(0.25))
                                        .clipShape(ChiselRect(cut: 4))
                                        .overlay(ChiselRect(cut: 4).stroke(Theme.C.bloodRed, lineWidth: 1))
                                }
                            }
                            Text("\(session.runs.count) run\(session.runs.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(Theme.C.textMuted)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.C.surfaceCard)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(sortedSessions[index])
                    }
                }
                .listRowSeparatorTint(Theme.C.borderStone)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.C.backgroundDeep)
            .navigationTitle("D2 Run Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button { showSortSheet = true } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                        Button { showingAddRun = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRun) {
            AddRunView(lastRunType: $lastRunType, lastMF: $lastMF, activeSession: activeSessions.first)
        }
        .sheet(isPresented: $showSortSheet) {
            SessionSortPickerView(sortOption: $sessionSortOption, sortAscending: $sortAscending)
                .presentationDetents([.height(160)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.C.surfaceRaised)
        }
    }
}

// MARK: - SessionSortPickerView

struct SessionSortPickerView: View {
    @Binding var sortOption: SessionSortOption
    @Binding var sortAscending: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SORT BY")
                .font(Theme.sectionHeader)
                .foregroundStyle(Theme.C.textMuted)
                .tracking(1.8)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 8)
            GoldDivider()
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            ForEach(SessionSortOption.allCases, id: \.self) { option in
                Button {
                    if sortOption == option {
                        sortAscending.toggle()
                    } else {
                        sortOption = option
                        sortAscending = false
                    }
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .foregroundStyle(Theme.C.textParchment)
                        Spacer()
                        if sortOption == option {
                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                .foregroundStyle(Theme.C.goldPrimary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 14)
                }
                if option != SessionSortOption.allCases.last {
                    Divider()
                        .background(Theme.C.borderStone)
                        .padding(.horizontal, 16)
                }
            }
            Spacer()
        }
    }
}

// MARK: - SessionDetailView

struct SessionDetailView: View {
    var session: DiabloSession
    @Environment(\.modelContext) var modelContext
    @Environment(MFSettings.self) var mfSettings
    @Query(sort: \RunType.sortOrder) var runTypes: [RunType]

    @State var sortOption: SortOption = .date
    @State var sortAscending: Bool = false
    @State var showSortSheet: Bool = false

    var sortedRuns: [DiabloRun] {
        let runs = session.runs
        switch sortOption {
        case .date:
            return runs.sorted { sortAscending ? $0.date < $1.date : $0.date > $1.date }
        case .duration:
            return runs.sorted { sortAscending ? $0.duration > $1.duration : $0.duration < $1.duration }
        case .magicFind:
            return runs.sorted { sortAscending ? $0.magicFind < $1.magicFind : $0.magicFind > $1.magicFind }
        }
    }

    private func defaultMF(for name: String) -> Int {
        runTypes.first { $0.name == name }?.defaultRecommendedMF ?? 0
    }

    var body: some View {
        List {
            ForEach(sortedRuns) { run in
                NavigationLink(destination: EditRunView(run: run)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(run.runTypeName)
                                .font(Theme.cardTitle)
                                .foregroundStyle(Theme.C.textParchment)
                            Text(
                                "\(String(format: "%.2f", run.durationInMinutes)) min · \(run.magicFind)% MF"
                            )
                            .font(.subheadline)
                            .foregroundStyle(Theme.C.textMuted)
                            Text(run.drops)
                                .font(.caption)
                                .foregroundStyle(Theme.C.textMuted.opacity(0.6))
                            Text(
                                "\(run.date, style: .relative) ago · \(run.date.formatted(date: .abbreviated, time: .shortened))"
                            )
                            .font(.caption2)
                            .foregroundStyle(Theme.C.textMuted.opacity(0.6))
                        }
                        Spacer()
                        let threshold = mfSettings.effectiveMF(
                            for: run.runTypeName,
                            defaultMF: defaultMF(for: run.runTypeName)
                        )
                        Image(
                            systemName: run.magicFind >= threshold
                                ? "checkmark.circle.fill"
                                : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(run.magicFind >= threshold ? Theme.C.emerald : Theme.C.amberWarning)
                        .font(.title3)
                    }
                }
                .listRowBackground(Theme.C.surfaceCard)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(sortedRuns[index])
                }
            }
            .listRowSeparatorTint(Theme.C.borderStone)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.C.backgroundDeep)
        .navigationTitle(session.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSortSheet = true } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .sheet(isPresented: $showSortSheet) {
            SortPickerView(sortOption: $sortOption, sortAscending: $sortAscending)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.C.surfaceRaised)
        }
    }
}

// MARK: - SortPickerView

struct SortPickerView: View {
    @Binding var sortOption: SortOption
    @Binding var sortAscending: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SORT BY")
                .font(Theme.sectionHeader)
                .foregroundStyle(Theme.C.textMuted)
                .tracking(1.8)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 8)
            GoldDivider()
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    if sortOption == option {
                        sortAscending.toggle()
                    } else {
                        sortOption = option
                        sortAscending = false
                    }
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .foregroundStyle(Theme.C.textParchment)
                        Spacer()
                        if sortOption == option {
                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                .foregroundStyle(Theme.C.goldPrimary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 14)
                }
                if option != SortOption.allCases.last {
                    Divider()
                        .background(Theme.C.borderStone)
                        .padding(.horizontal, 16)
                }
            }
            Spacer()
        }
    }
}

// MARK: - AddRunView

private enum RunPhase { case setup, active, postRun }

struct AddRunView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Binding var lastRunType: String
    @Binding var lastMF: Int
    var activeSession: DiabloSession? = nil
    @Query(sort: \RunType.sortOrder) var runTypes: [RunType]

    @State private var phase: RunPhase = .setup
    @State private var selectedRunTypeName: String = ""
    @State private var magicFind: String = ""
    @State private var drops: String = ""
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer? = nil
    @State private var runStartDate: Date = Date()
    @State private var currentSession: DiabloSession? = nil
    @State private var showEndSessionConfirmation: Bool = false

    var formattedTime: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    var displayedRunTypeName: String {
        selectedRunTypeName.isEmpty ? (runTypes.first?.name ?? "") : selectedRunTypeName
    }

    var sessionIsLocked: Bool {
        activeSession != nil || currentSession != nil
    }

    func startTimer() {
        runStartDate = Date()
        elapsedSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func saveRunData() {
        let newRun = DiabloRun(
            runTypeName: displayedRunTypeName,
            duration: elapsedSeconds,
            magicFind: Int(magicFind) ?? 0,
            drops: drops.isEmpty ? "Nothing" : drops,
            startDate: runStartDate
        )
        lastRunType = displayedRunTypeName
        lastMF = Int(magicFind) ?? lastMF

        let session: DiabloSession
        if let existing = activeSession ?? currentSession {
            session = existing
        } else {
            let s = DiabloSession(
                name: makeSessionName(runTypeName: displayedRunTypeName, in: modelContext),
                runTypeName: displayedRunTypeName
            )
            s.startDate = runStartDate
            modelContext.insert(s)
            currentSession = s
            session = s
        }
        if session.startDate == nil { session.startDate = runStartDate }
        session.runs.append(newRun)
        session.endDate = Date()
        modelContext.insert(newRun)
    }

    func saveRun() {
        saveRunData()
        dismiss()
    }

    func saveAndNew() {
        saveRunData()
        drops = ""
        elapsedSeconds = 0
        withAnimation(.easeInOut(duration: 0.25)) { phase = .setup }
    }

    func saveAndEndSession() {
        saveRunData()
        (activeSession ?? currentSession)?.isActive = false
        dismiss()
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .setup:
                    Form {
                        Section("Run Type") {
                            if sessionIsLocked {
                                Text(displayedRunTypeName)
                                    .foregroundStyle(Theme.C.textMuted)
                            } else {
                                Picker("Run Type", selection: $selectedRunTypeName) {
                                    ForEach(runTypes) { rt in
                                        Text(rt.name).tag(rt.name)
                                    }
                                }
                            }
                        }
                        Section("Magic Find") {
                            TextField("%", text: $magicFind)
                                .keyboardType(.numberPad)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.C.backgroundDeep)
                case .active:
                    VStack(spacing: 16) {
                        Spacer()
                        Text("\(displayedRunTypeName)  ·  \(magicFind)% MF")
                            .font(Theme.sectionHeader)
                            .foregroundStyle(Theme.C.textMuted)
                            .tracking(1.5)
                        GoldDivider()
                            .frame(width: 200)
                        Text(formattedTime)
                            .font(Theme.timerLarge)
                            .foregroundStyle(Theme.C.goldBright)
                            .monospacedDigit()
                            .shadow(color: Theme.C.goldPrimary.opacity(0.5), radius: 12, x: 0, y: 0)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Theme.C.backgroundDeep)
                case .postRun:
                    VStack(spacing: 0) {
                        VStack(spacing: 6) {
                            Text("RUN COMPLETE")
                                .font(Theme.sectionHeader)
                                .foregroundStyle(Theme.C.textMuted)
                                .tracking(1.8)
                            GoldDivider()
                                .frame(width: 160)
                            Text(formattedTime)
                                .font(Theme.exocet(48))
                                .foregroundStyle(Theme.C.goldPrimary)
                        }
                        .padding(.vertical, 28)
                        Form {
                            Section("Notable Drops") {
                                TextField("Leave empty for nothing", text: $drops)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Theme.C.backgroundDeep)
                    }
                    .background(Theme.C.backgroundDeep)
                }
            }
            .navigationTitle(
                phase == .setup ? "New Run" : phase == .active ? "Run in Progress" : "Save Run"
            )
            .background(Theme.C.backgroundDeep)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { stopTimer(); dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Group {
                    switch phase {
                    case .setup:
                        Button("Start Run") {
                            withAnimation(.easeInOut(duration: 0.25)) { phase = .active }
                            startTimer()
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.C.goldPrimary)
                        .controlSize(.large)
                        .padding()
                    case .active:
                        Button("End Run") {
                            stopTimer()
                            withAnimation(.easeInOut(duration: 0.25)) { phase = .postRun }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.C.bloodRedBright)
                        .controlSize(.large)
                        .padding()
                    case .postRun:
                        VStack(spacing: 12) {
                            Button("Save") { saveRun() }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.C.goldPrimary)
                                .controlSize(.large)
                            Button("Save & New") { saveAndNew() }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(.bordered)
                                .tint(Theme.C.goldPrimary)
                                .controlSize(.large)
                            Button("Save and End Session") {
                                showEndSessionConfirmation = true
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)
                            .tint(Theme.C.bloodRedBright)
                            .controlSize(.large)
                        }
                        .padding()
                    }
                }
                .background(Theme.C.backgroundDeep.opacity(0.95))
            }
            .confirmationDialog(
                "End Session?",
                isPresented: $showEndSessionConfirmation,
                titleVisibility: .visible
            ) {
                Button("End Session", role: .destructive) { saveAndEndSession() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will save the run and mark the session as complete.")
            }
            .interactiveDismissDisabled(phase == .active)
            .onAppear {
                if let active = activeSession {
                    selectedRunTypeName = active.runTypeName
                } else {
                    let available = runTypes.map(\.name)
                    selectedRunTypeName = available.contains(lastRunType)
                        ? lastRunType
                        : (runTypes.first?.name ?? "")
                }
                magicFind = lastMF > 0 ? String(lastMF) : ""
            }
            .onDisappear { stopTimer() }
        }
    }
}

// MARK: - EditRunView

struct EditRunView: View {
    var run: DiabloRun
    @Environment(\.dismiss) var dismiss
    @Query(sort: \RunType.sortOrder) var runTypes: [RunType]
    @State var runTypeName: String
    @State var duration: String
    @State var magicFind: String
    @State var drops: String

    init(run: DiabloRun) {
        self.run = run
        self._runTypeName = State(initialValue: run.runTypeName)
        self._duration = State(initialValue: String(run.duration))
        self._magicFind = State(initialValue: String(run.magicFind))
        self._drops = State(initialValue: run.drops)
    }

    var body: some View {
        Form {
            Section("Run Type") {
                Picker("Run Type", selection: $runTypeName) {
                    ForEach(runTypes) { rt in
                        Text(rt.name).tag(rt.name)
                    }
                    if !runTypes.contains(where: { $0.name == run.runTypeName }) {
                        Text(run.runTypeName).tag(run.runTypeName)
                    }
                }
            }
            Section("Duration") {
                TextField("Seconds", text: $duration)
                    .keyboardType(.numberPad)
            }
            Section("Magic Find") {
                TextField("%", text: $magicFind)
                    .keyboardType(.numberPad)
            }
            Section("Drops") {
                TextField("Leave empty for \"nothing\"", text: $drops)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.C.backgroundDeep)
        .navigationTitle("Edit Run")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    run.runTypeName = runTypeName
                    run.duration = Int(duration) ?? run.duration
                    run.magicFind = Int(magicFind) ?? run.magicFind
                    run.drops = drops.isEmpty ? run.drops : drops
                    dismiss()
                }
            }
        }
    }
}
