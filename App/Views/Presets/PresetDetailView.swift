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
                VStack(spacing: 6.0) {
                    PresetIconView(preset: preset, size: 64.0)
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
