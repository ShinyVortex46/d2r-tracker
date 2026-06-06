import SwiftUI

// MARK: - DropChipView

struct DropChipView: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(Theme.badge)
                .foregroundStyle(Theme.C.textParchment)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.C.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Theme.C.surfaceRaised)
        .clipShape(ChiselRect(cut: 3))
        .overlay(
            ChiselRect(cut: 3)
                .stroke(Theme.C.borderStone, lineWidth: 1)
        )
    }
}

// MARK: - DropsChipRow

struct DropsChipRow: View {
    let drops: [String]
    let onRemove: (String) -> Void
    let onAddTapped: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(drops, id: \.self) { name in
                    DropChipView(name: name) { onRemove(name) }
                }
                Button(action: onAddTapped) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Add Drops")
                            .font(Theme.badge)
                    }
                    .foregroundStyle(Theme.C.goldPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Theme.C.goldPrimary.opacity(0.12))
                    .clipShape(ChiselRect(cut: 3))
                    .overlay(
                        ChiselRect(cut: 3)
                            .stroke(Theme.C.goldPrimary.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - DropsPickerView

struct DropsPickerView: View {
    @Binding var selectedDrops: [String]
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory = .rune

    private var filteredItems: [GameItem] {
        let byCategory = ItemDatabase.all.filter { $0.category == selectedCategory }
        guard !searchText.isEmpty else { return byCategory }
        return byCategory.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryBar
                List {
                    ForEach(filteredItems) { item in
                        itemRow(item)
                            .listRowBackground(
                                selectedDrops.contains(item.name)
                                    ? Theme.C.goldPrimary.opacity(0.1)
                                    : Theme.C.surfaceCard
                            )
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.C.backgroundDeep)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search items")
            }
            .background(Theme.C.backgroundDeep)
            .navigationTitle("Select Drops")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.C.goldPrimary)
                }
            }
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ItemCategory.allCases, id: \.self) { cat in
                    let isActive = cat == .rune
                    let isSelected = selectedCategory == cat
                    Button {
                        if isActive { selectedCategory = cat }
                    } label: {
                        Text(cat.rawValue.uppercased())
                            .font(Theme.sectionHeader)
                            .tracking(1.4)
                            .foregroundStyle(
                                isActive
                                    ? (isSelected ? Theme.C.goldBright : Theme.C.textMuted)
                                    : Theme.C.textMuted.opacity(0.35)
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                isSelected && isActive
                                    ? Theme.C.goldPrimary.opacity(0.15)
                                    : Color.clear
                            )
                            .clipShape(ChiselRect(cut: 4))
                            .overlay(
                                ChiselRect(cut: 4)
                                    .stroke(
                                        isSelected && isActive
                                            ? Theme.C.goldPrimary.opacity(0.6)
                                            : Theme.C.borderStone.opacity(isActive ? 0.6 : 0.25),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .disabled(!isActive)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Theme.C.surfaceCard)
    }

    @ViewBuilder
    private func itemRow(_ item: GameItem) -> some View {
        Button {
            if selectedDrops.contains(item.name) {
                selectedDrops.removeAll { $0 == item.name }
            } else {
                selectedDrops.append(item.name)
            }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(rarityColor(for: item.rarity))
                    .frame(width: 8, height: 8)
                Text(item.name)
                    .font(Theme.exocetLight(13))
                    .foregroundStyle(Theme.C.textParchment)
                Spacer()
                if selectedDrops.contains(item.name) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.C.goldBright)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func rarityColor(for rarity: Int) -> Color {
        switch rarity {
        case 1...10:  return Theme.C.textMuted.opacity(0.5)
        case 11...20: return Theme.C.goldPrimary.opacity(0.7)
        case 21...27: return Theme.C.goldBright
        default:      return Theme.C.bloodRedBright
        }
    }
}
