import SafariServices
import SwiftUI

struct PresetDetailView: View {

    @Environment(PresetUpdater.self) var presetUpdater

    @State var preset: Preset
    var presetStore: PresetStore
    @State var isShowingEditor: Bool = false
    @State var safariURL: URL?

    // The pending update for this preset, if any.
    private var pendingUpdate: PresetUpdater.PendingPresetUpdate? {
        presetUpdater.pendingUpdates.first { $0.presetName == preset.name }
    }

    private func applyPendingUpdate(_ update: PresetUpdater.PendingPresetUpdate) {
        presetUpdater.applyUpdate(update)
        presetStore.loadPresets()
        // Built-in presets are reloaded with fresh ids, so re-bind by name.
        if let updated = presetStore.presets.first(where: { $0.name == preset.name }) {
            preset = updated
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 6.0) {
                    PresetIconView(preset: preset, size: 64.0)
                        .shadow(color: .black.opacity(0.15), radius: 6.0, y: 2.0)
                    Text(preset.displayName)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    if let viewport = preset.viewport, viewport != .none {
                        Text(viewport.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12.0)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if preset.isBuiltIn {
                Section {
                    Toggle("Presets.Detail.Show", isOn: Binding(
                        get: { !presetStore.hiddenPresetNames.contains(preset.name) },
                        set: { shouldShow in
                            withAnimation(.smooth.speed(2)) {
                                if shouldShow {
                                    presetStore.unhideBuiltInPreset(name: preset.name)
                                } else {
                                    presetStore.hideBuiltInPreset(preset)
                                }
                            }
                        }
                    ))
                }
            }

            if let pendingUpdate {
                Section("Presets.Detail.UpdateAvailable") {
                    HStack(spacing: 12.0) {
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text(preset.displayName)
                            Text("More.PresetUpdates.VersionChange \(pendingUpdate.currentVersion) \(pendingUpdate.updatedVersion)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Shared.Update") {
                            withAnimation(.smooth.speed(2)) { applyPendingUpdate(pendingUpdate) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .fontWeight(.bold)
                    }
                    .padding(.vertical, 2.0)
                }
            }

            Section("UserAgent") {
                Text(preset.userAgent.isEmpty
                     ? NSLocalizedString("Presets.Detail.Default", comment: "")
                     : preset.userAgent)
                    .font(.monospaced(.custom("", size: 14.0, relativeTo: .body))())
                    .textSelection(.enabled)
            }

            if !preset.allSources.isEmpty {
                Section("Presets.Detail.References") {
                    ForEach(Array(preset.allSources.enumerated()), id: \.offset) { index, urlString in
                        Button {
                            if let url = URL(string: urlString) {
                                safariURL = url
                            }
                        } label: {
                            HStack {
                                Image(systemName: "safari")
                                    .foregroundStyle(.accent)
                                Text("\(index + 1). \(URL(string: urlString)?.host ?? urlString)")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .contentMargins(.top, 0.0, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .gradientBackground()
        .navigationTitle(preset.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Spacer()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Shared.Edit") {
                    isShowingEditor = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            PresetEditorView(mode: .edit, presetStore: presetStore, editingPreset: preset)
        }
        .onChange(of: isShowingEditor) {
            if !isShowingEditor {
                if let updated = presetStore.presets.first(where: { $0.id == preset.id }) {
                    preset = updated
                }
            }
        }
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
