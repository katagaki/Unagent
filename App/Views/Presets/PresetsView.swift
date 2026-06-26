//
//  PresetsView.swift
//  Unagent
//

import SwiftUI

struct PresetsView: View {

    @Environment(PresetStore.self) var presetStore

    @State var isShowingNewPreset: Bool = false
    @State private var expandedCategories: Set<PresetCategory> = [.browsers]

    // The "Don't Change" preset, pinned above the categorised sections.
    private var defaultPreset: Preset? {
        presetStore.builtInPresets.first { $0.userAgent.isEmpty }
    }

    private func builtInPresets(in category: PresetCategory) -> [Preset] {
        presetStore.builtInPresets.filter {
            !$0.userAgent.isEmpty && $0.resolvedCategory == category
        }
    }

    // Defensive: any built-in that carries an unknown/missing category is still shown.
    private var uncategorizedBuiltIns: [Preset] {
        presetStore.builtInPresets.filter {
            !$0.userAgent.isEmpty && $0.resolvedCategory == nil
        }
    }

    private func isHidden(_ preset: Preset) -> Bool {
        presetStore.hiddenPresetNames.contains(preset.name)
    }

    private func toggleExpansion(_ category: PresetCategory) {
        if expandedCategories.contains(category) {
            expandedCategories.remove(category)
        } else {
            expandedCategories.insert(category)
        }
    }

    var body: some View {
        Group {
            if let defaultPreset {
                Section {
                    NavigationLink {
                        PresetDetailView(preset: defaultPreset, presetStore: presetStore)
                    } label: {
                        PresetRowView(preset: defaultPreset)
                    }
                }
            }

            ForEach(PresetCategory.allCases) { category in
                let items = builtInPresets(in: category)
                if !items.isEmpty {
                    Section {
                        Button {
                            withAnimation { toggleExpansion(category) }
                        } label: {
                            HStack {
                                Text(category.displayName)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(expandedCategories.contains(category) ? 90 : 0))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if expandedCategories.contains(category) {
                            ForEach(items) { preset in
                                presetRow(preset)
                            }
                        }
                    }
                }
            }

            if !uncategorizedBuiltIns.isEmpty {
                Section {
                    ForEach(uncategorizedBuiltIns) { preset in
                        presetRow(preset)
                    }
                }
            }

            Section {
                if presetStore.customPresets.isEmpty {
                    ContentUnavailableView(
                        "Presets.Custom.EmptyTitle",
                        systemImage: "star.slash",
                        description: Text("Presets.Custom.EmptyText")
                    )
                } else {
                    ForEach(presetStore.customPresets) { preset in
                        NavigationLink {
                            PresetDetailView(preset: preset, presetStore: presetStore)
                        } label: {
                            PresetRowView(preset: preset)
                        }
                    }
                    .onDelete { indexSet in
                        let custom = presetStore.customPresets
                        for index in indexSet {
                            presetStore.deletePreset(custom[index])
                        }
                    }
                }
            } header: {
                HStack(alignment: .center) {
                    Text("Presets.Custom")
                    Spacer()
                    Button("Shared.Add", systemImage: "plus") {
                        isShowingNewPreset = true
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingNewPreset) {
            PresetEditorView(mode: .new, presetStore: presetStore)
        }
    }

    @ViewBuilder
    private func presetRow(_ preset: Preset) -> some View {
        let hidden = isHidden(preset)
        NavigationLink {
            PresetDetailView(preset: preset, presetStore: presetStore)
        } label: {
            PresetRowView(preset: preset)
        }
        .opacity(hidden ? 0.4 : 1.0)
        .swipeActions(edge: .trailing) {
            if hidden {
                Button("Presets.Unhide", systemImage: "eye") {
                    withAnimation { presetStore.unhideBuiltInPreset(name: preset.name) }
                }
                .tint(.accentColor)
            } else {
                Button("Presets.Hide", systemImage: "eye.slash") {
                    withAnimation { presetStore.hideBuiltInPreset(preset) }
                }
                .tint(.orange)
            }
        }
        .contextMenu {
            if hidden {
                Button("Presets.Unhide", systemImage: "eye") {
                    withAnimation { presetStore.unhideBuiltInPreset(name: preset.name) }
                }
            } else {
                Button("Presets.Hide", systemImage: "eye.slash") {
                    withAnimation { presetStore.hideBuiltInPreset(preset) }
                }
            }
        }
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
