import SwiftUI

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
        return sortedAlphabetically(items)
    }

    private func sortedAlphabetically(_ presets: [Preset]) -> [Preset] {
        presets.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
    }

    private var uncategorizedBuiltIns: [Preset] {
        sortedAlphabetically(
            presetStore.builtInPresets.filter {
                !$0.userAgent.isEmpty && $0.resolvedCategory == nil
            }
        )
    }

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
        case .custom: sortedAlphabetically(presetStore.customPresets)
        }
    }

    private func title(for segment: PresetSegment) -> String {
        switch segment {
        case .category(let category): category.displayName
        case .uncategorized: NSLocalizedString("Presets.Category.Other", comment: "")
        case .custom: NSLocalizedString("Presets.Category.Custom", comment: "")
        }
    }

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
        VStack(alignment: .leading, spacing: GroupedMetrics.headerSpacing) {
            Text("Shared.Presets")
                .font(.body.weight(.semibold))
                .padding(.horizontal, GroupedMetrics.headerInset)
            carousel
            GroupedSection(showsBackground: !isSelectedSegmentEmpty) {
                segmentContent
            }
        }
        .sheet(isPresented: $isShowingNewPreset) {
            PresetEditorView(mode: .new, presetStore: presetStore)
        }
        .onAppear {
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
            .padding(.horizontal, GroupedMetrics.horizontalInset)
        }
    }

    private var isSelectedSegmentEmpty: Bool {
        selectedSegment == .custom && presetStore.customPresets.isEmpty
    }

    // MARK: - Segment content

    @ViewBuilder
    private var segmentContent: some View {
        switch selectedSegment {
        case .custom:
            let customPresets = presets(in: .custom)
            if customPresets.isEmpty {
                ContentUnavailableView(
                    "Presets.Custom.EmptyTitle",
                    systemImage: "star.slash",
                    description: Text("Presets.Custom.EmptyText")
                )
            } else {
                ForEach(Array(customPresets.enumerated()), id: \.element.id) { index, preset in
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
                    .fontWeight(.semibold)
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
        HStack(spacing: 12.0) {
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
