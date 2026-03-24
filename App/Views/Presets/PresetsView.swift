//
//  PresetsView.swift
//  Unagent
//

import SwiftUI

struct PresetsView: View {

    @State var presetStore = PresetStore()
    @State var presetUpdater = PresetUpdater()
    @State var isShowingNewPreset: Bool = false
    @State var selectedTab: PresetTab = .visible

    enum PresetTab: String, CaseIterable {
        case visible
        case hidden
    }

    var displayedBuiltInPresets: [Preset] {
        presetStore.visibleBuiltInPresets.filter { !$0.userAgent.isEmpty }
    }

    var hiddenBuiltInPresets: [Preset] {
        presetStore.builtInPresets.filter { presetStore.hiddenPresetNames.contains($0.name) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Presets.Filter", selection: $selectedTab) {
                        Text("Presets.Visible").tag(PresetTab.visible)
                        Text("Presets.Hidden").tag(PresetTab.hidden)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch selectedTab {
                case .visible:
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

                case .hidden:
                    if hiddenBuiltInPresets.isEmpty {
                        ContentUnavailableView(
                            "Presets.Hidden.EmptyTitle",
                            systemImage: "eye",
                            description: Text("Presets.Hidden.EmptyText")
                        )
                    } else {
                        Section {
                            ForEach(hiddenBuiltInPresets) { preset in
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
                                    Text(preset.name)
                                        .foregroundStyle(.secondary)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button("Presets.Unhide") {
                                        withAnimation {
                                            presetStore.unhideBuiltInPreset(name: preset.name)
                                        }
                                    }
                                    .tint(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .gradientBackground()
            .navigationTitle("ViewTitle.Presets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await presetUpdater.checkForUpdates()
                            presetStore.loadPresets()
                        }
                    } label: {
                        if presetUpdater.isChecking {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(presetUpdater.isChecking)
                }
            }
            .alert(
                "Presets.Update.Title",
                isPresented: Binding(
                    get: { presetUpdater.updateResult != nil },
                    set: { if !$0 { presetUpdater.updateResult = nil } }
                )
            ) {
                Button("Shared.OK", role: .cancel) {
                    presetUpdater.updateResult = nil
                }
            } message: {
                switch presetUpdater.updateResult {
                case .updated(let count):
                    Text("Presets.Update.Updated \(count)")
                case .noUpdates:
                    Text("Presets.Update.NoUpdates")
                case .failed(let message):
                    Text("Presets.Update.Failed \(message)")
                case nil:
                    EmptyView()
                }
            }
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
