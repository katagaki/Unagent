//
//  PresetsView.swift
//  Unagent
//

import SwiftUI

struct PresetsView: View {

    @State var presetStore = PresetStore()
    @State var isShowingNewPreset: Bool = false

    var displayedBuiltInPresets: [Preset] {
        presetStore.visibleBuiltInPresets.filter { !$0.userAgent.isEmpty }
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
                            .swipeActions(edge: .trailing) {
                                Button("Presets.Hide", role: .destructive) {
                                    withAnimation {
                                        presetStore.hideBuiltInPreset(preset)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Presets.BuiltIn")
                    }
                }

                if !presetStore.hiddenPresetNames.isEmpty {
                    Section {
                        ForEach(Array(presetStore.hiddenPresetNames).sorted(), id: \.self) { name in
                            HStack {
                                Text(name)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Presets.Unhide") {
                                    withAnimation {
                                        presetStore.unhideBuiltInPreset(name: name)
                                    }
                                }
                                .tint(.accentColor)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Presets.Hidden")
                            Spacer()
                            Button("Presets.UnhideAll") {
                                withAnimation {
                                    presetStore.unhideAllBuiltInPresets()
                                }
                            }
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
