//
//  MoreView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

struct MoreView: View {

    @Environment(PresetUpdater.self) var presetUpdater
    @Environment(PresetStore.self) var presetStore

    @State var isAutoRefreshEnabled: Bool = defaults.bool(forKey: "AutoRefreshEnabled")

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if presetUpdater.pendingUpdates.isEmpty {
                        ContentUnavailableView(
                            "More.PresetUpdates.NoUpdates",
                            systemImage: "checkmark.circle",
                            description: Text("More.PresetUpdates.NoUpdates.Description")
                        )
                    } else {
                        ForEach(presetUpdater.pendingUpdates) { update in
                            PresetUpdateRow(update: update) {
                                withAnimation {
                                    presetUpdater.applyUpdate(update)
                                    presetStore.loadPresets()
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("More.PresetUpdates")
                        Spacer()
                        if !presetUpdater.pendingUpdates.isEmpty {
                            Button("More.PresetUpdates.UpdateAll") {
                                withAnimation {
                                    presetUpdater.applyAllPendingUpdates()
                                    presetStore.loadPresets()
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                }

                Section {
                    Toggle("More.AutoRefresh", isOn: $isAutoRefreshEnabled)
                        .onChange(of: isAutoRefreshEnabled) { _, newValue in
                            defaults.set(newValue, forKey: "AutoRefreshEnabled")
                            defaults.set(true, forKey: "ShouldExtensionUpdate")
                        }
                } header: {
                    Text("More.General")
                } footer: {
                    Text("More.AutoRefresh.Description")
                }

                Section {
                    Link(destination: URL(string: "https://github.com/katagaki/Unagent")!) {
                        HStack {
                            Text("More.SourceCode")
                            Spacer()
                            Text("katagaki/Unagent")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                    NavigationLink {
                        AttributionsView()
                    } label: {
                        Text("More.Attribution")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .gradientBackground()
            .navigationTitle("ViewTitle.More")
            .refreshable {
                await presetUpdater.checkForUpdatesQuietly()
            }
        }
    }
}

struct PresetUpdateRow: View {

    let update: PresetUpdater.PendingPresetUpdate
    let onUpdate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if UIImage(named: update.imageName) != nil {
                Image(update.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: update.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(update.presetName)
                Text("More.PresetUpdates.VersionChange \(update.currentVersion) \(update.updatedVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Shared.Update") {
                onUpdate()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}
