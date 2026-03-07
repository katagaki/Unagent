//
//  PresetDetailView.swift
//  Unagent
//

import SafariServices
import SwiftUI

struct PresetDetailView: View {

    @State var preset: Preset
    var presetStore: PresetStore
    @State var isShowingEditor: Bool = false
    @State var safariURL: URL?

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Presets.Detail.Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(preset.name)
                }
                if let viewport = preset.viewport, viewport != .none {
                    HStack {
                        Text("Viewport")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(viewport.displayName)
                    }
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
                    ForEach(preset.allSources, id: \.self) { urlString in
                        Button {
                            if let url = URL(string: urlString) {
                                safariURL = url
                            }
                        } label: {
                            HStack {
                                Text(urlString)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                Spacer()
                                Image(systemName: "safari")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(preset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                // Refresh the preset from the store after editing
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
