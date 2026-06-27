import SwiftUI

// A page in the presets carousel: a built-in category, the catch-all bucket for
// built-ins with an unknown category, or the user's custom presets.
enum PresetSegment: Hashable, Identifiable {
    case category(PresetCategory)
    case uncategorized
    case custom

    var id: String {
        switch self {
        case .category(let category): "category.\(category.rawValue)"
        case .uncategorized: "uncategorized"
        case .custom: "custom"
        }
    }
}

struct PresetsView: View {

    @Environment(PresetStore.self) var presetStore
    @Environment(PresetUpdater.self) var presetUpdater

    @Binding var isShowingNewPreset: Bool
    @State private var selectedSegment: PresetSegment = .category(.browsers)

    private func builtInPresets(in category: PresetCategory) -> [Preset] {
        let items = presetStore.builtInPresets.filter {
            !$0.userAgent.isEmpty && $0.resolvedCategory == category
        }
        return sortedByPlatform(items)
    }

    // Keep brands grouped in their original order, and within each brand order the
    // platform variants iOS/iPadOS → macOS → Android → Windows → Linux/others.
    private func sortedByPlatform(_ presets: [Preset]) -> [Preset] {
        var brandOrder: [String: Int] = [:]
        for preset in presets where brandOrder[brandKey(preset.name)] == nil {
            brandOrder[brandKey(preset.name)] = brandOrder.count
        }
        return presets.enumerated().sorted { lhs, rhs in
            let lBrand = brandOrder[brandKey(lhs.element.name)] ?? 0
            let rBrand = brandOrder[brandKey(rhs.element.name)] ?? 0
            if lBrand != rBrand { return lBrand < rBrand }
            let lPlatform = platformRank(lhs.element.name)
            let rPlatform = platformRank(rhs.element.name)
            if lPlatform != rPlatform { return lPlatform < rPlatform }
            return lhs.offset < rhs.offset // stable for anything still equal
        }.map(\.element)
    }

    private func platformRank(_ name: String) -> Int {
        switch lastParenthetical(name)?.lowercased() {
        case "ios": return 0
        case "ipados": return 1
        case "macos": return 2
        case "android": return 3
        case "windows": return 4
        case "linux": return 5
        default: return 6
        }
    }

    // The brand is the name without its trailing platform qualifier,
    // e.g. "Google Chrome (iOS)" → "Google Chrome".
    private func brandKey(_ name: String) -> String {
        guard let separator = name.range(of: " (", options: .backwards) else { return name }
        return String(name[..<separator.lowerBound])
    }

    private func lastParenthetical(_ name: String) -> String? {
        guard let close = name.lastIndex(of: ")"),
              let open = name[..<close].lastIndex(of: "(") else { return nil }
        return String(name[name.index(after: open)..<close])
    }

    // Defensive: any built-in that carries an unknown/missing category is still shown.
    private var uncategorizedBuiltIns: [Preset] {
        presetStore.builtInPresets.filter {
            !$0.userAgent.isEmpty && $0.resolvedCategory == nil
        }
    }

    // The segments that actually have content, in display order. Custom is
    // always offered so the user has somewhere to add their own presets.
    private var availableSegments: [PresetSegment] {
        var segments: [PresetSegment] = PresetCategory.allCases
            .filter { !builtInPresets(in: $0).isEmpty }
            .map { .category($0) }
        if !uncategorizedBuiltIns.isEmpty {
            segments.append(.uncategorized)
        }
        segments.append(.custom)
        return segments
    }

    private func presets(in segment: PresetSegment) -> [Preset] {
        switch segment {
        case .category(let category): builtInPresets(in: category)
        case .uncategorized: uncategorizedBuiltIns
        case .custom: presetStore.customPresets
        }
    }

    private func title(for segment: PresetSegment) -> String {
        switch segment {
        case .category(let category): category.displayName
        case .uncategorized: NSLocalizedString("Presets.Category.Other", comment: "")
        case .custom: NSLocalizedString("Presets.Category.Custom", comment: "")
        }
    }

    // How many presets in a segment have a pending user-agent update — drives
    // the red badge on the carousel capsule.
    private func pendingCount(in segment: PresetSegment) -> Int {
        let names = Set(presetUpdater.pendingUpdates.map(\.presetName))
        return presets(in: segment).filter { names.contains($0.name) }.count
    }

    private func isHidden(_ preset: Preset) -> Bool {
        presetStore.hiddenPresetNames.contains(preset.name)
    }

    private func hasUpdate(_ preset: Preset) -> Bool {
        presetUpdater.pendingUpdates.contains { $0.presetName == preset.name }
    }

    private var updateBadge: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 9.0, height: 9.0)
    }

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: GroupedMetrics.headerSpacing) {
                Text("Shared.Presets")
                    .font(.body.weight(.semibold))
                    // Align with the other section headers and the capsule labels
                    // (capsule text sits at carousel inset + capsule padding).
                    .padding(.horizontal, GroupedMetrics.headerInset)
                carousel
            }

            GroupedSection(showsBackground: !isSelectedSegmentEmpty) {
                segmentContent
            }
        }
        .sheet(isPresented: $isShowingNewPreset) {
            PresetEditorView(mode: .new, presetStore: presetStore)
        }
        .onAppear {
            // Keep the selection valid if categories appeared/disappeared.
            if !availableSegments.contains(selectedSegment),
               let first = availableSegments.first {
                selectedSegment = first
            }
        }
    }

    // MARK: - Carousel

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8.0) {
                ForEach(availableSegments) { segment in
                    PresetCategoryCapsule(
                        title: title(for: segment),
                        isSelected: segment == selectedSegment,
                        badgeCount: pendingCount(in: segment)
                    ) {
                        withAnimation(.smooth.speed(2)) { selectedSegment = segment }
                    }
                }
            }
            // Inset so the first/last capsule line up with the cards, while the
            // scrollable area still runs edge to edge.
            .padding(.horizontal, GroupedMetrics.horizontalInset)
        }
    }

    // The custom segment is the only one that can be empty (built-in categories
    // are only listed when populated).
    private var isSelectedSegmentEmpty: Bool {
        selectedSegment == .custom && presetStore.customPresets.isEmpty
    }

    // MARK: - Segment content

    @ViewBuilder
    private var segmentContent: some View {
        switch selectedSegment {
        case .custom:
            if presetStore.customPresets.isEmpty {
                ContentUnavailableView(
                    "Presets.Custom.EmptyTitle",
                    systemImage: "star.slash",
                    description: Text("Presets.Custom.EmptyText")
                )
            } else {
                ForEach(Array(presetStore.customPresets.enumerated()), id: \.element.id) { index, preset in
                    if index > 0 { GroupedDivider() }
                    GroupedNavigationRow {
                        PresetDetailView(preset: preset, presetStore: presetStore)
                    } label: {
                        PresetRowView(preset: preset)
                    } accessory: {
                        if hasUpdate(preset) { updateBadge }
                    }
                    .contextMenu {
                        Button("Shared.Delete", role: .destructive) {
                            withAnimation(.smooth.speed(2)) { presetStore.deletePreset(preset) }
                        }
                    }
                }
            }
        default:
            let items = presets(in: selectedSegment)
            ForEach(Array(items.enumerated()), id: \.element.id) { index, preset in
                if index > 0 { GroupedDivider() }
                presetRow(preset)
            }
        }
    }

    @ViewBuilder
    private func presetRow(_ preset: Preset) -> some View {
        let hidden = isHidden(preset)
        GroupedNavigationRow {
            PresetDetailView(preset: preset, presetStore: presetStore)
        } label: {
            PresetRowView(preset: preset)
                .opacity(hidden ? 0.4 : 1.0)
        } accessory: {
            if hasUpdate(preset) { updateBadge }
        }
        .contextMenu {
            if hidden {
                Button("Presets.Unhide", systemImage: "eye") {
                    withAnimation(.smooth.speed(2)) { presetStore.unhideBuiltInPreset(name: preset.name) }
                }
            } else {
                Button("Presets.Hide", systemImage: "eye.slash") {
                    withAnimation(.smooth.speed(2)) { presetStore.hideBuiltInPreset(preset) }
                }
            }
        }
    }
}

struct PresetCategoryCapsule: View {

    let title: String
    let isSelected: Bool
    let badgeCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6.0) {
                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                if badgeCount > 0 {
                    Text(String(badgeCount))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5.0)
                        .frame(minWidth: 18.0, minHeight: 18.0)
                        .background(Capsule().fill(Color.red))
                }
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 8.0)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected
                          ? Color.accentColor
                          : Color(uiColor: .secondarySystemGroupedBackground))
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PresetRowView: View {
    var preset: Preset

    var body: some View {
        HStack(spacing: 8.0) {
            PresetIconView(preset: preset)
            Text(preset.displayName)
                .lineLimit(1)
            if let viewport = preset.viewport,
               viewport != .none,
               let icon = viewport.iconName {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(viewport.displayName)
            }
        }
    }
}
