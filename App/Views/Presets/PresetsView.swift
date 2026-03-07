//
//  PresetsView.swift
//  Unagent
//

import SwiftUI

struct PresetsView: View {

    @State var presetStore = PresetStore()
    @State var isShowingNewPreset: Bool = false

    var displayedBuiltInPresets: [Preset] {
        presetStore.builtInPresets.filter { !$0.userAgent.isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                if !displayedBuiltInPresets.isEmpty {
                    Section {
                        ForEach(displayedBuiltInPresets) { preset in
                            NavigationLink {
                                PresetDetailView(preset: preset, presetStore: presetStore)
                            } label: {
                                PresetRowView(preset: preset)
                            }
                        }
                    } header: {
                        Text("Presets.BuiltIn")
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
            .navigationTitle("ViewTitle.Presets")
            .sheet(isPresented: $isShowingNewPreset) {
                PresetEditorView(mode: .new, presetStore: presetStore)
            }
        }
    }
}

struct PresetRowView: View {
    var preset: Preset

    var body: some View {
        HStack(spacing: 8.0) {
            if UIImage(named: preset.imageName) != nil {
                Image(preset.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: preset.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                if !preset.userAgent.isEmpty {
                    Text(preset.userAgent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
