//
//  PresetEditorView.swift
//  Unagent
//

import SwiftUI

struct PresetEditorView: View {

    @Environment(\.dismiss) var dismiss

    var mode: EditorMode
    var presetStore: PresetStore
    var editingPreset: Preset?

    @State private var name: String = ""
    @State private var imageName: String = "Safari"
    @State private var userAgent: String = ""
    @State private var source: String = ""
    @State private var viewport: Viewport? = nil
    @State private var isShowingIconPicker: Bool = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Presets.Editor.Name", text: $name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Presets.Detail.Name")
                }

                Section {
                    Button {
                        isShowingIconPicker = true
                    } label: {
                        HStack {
                            Text("Presets.Editor.Icon")
                            Spacer()
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Presets.Editor.Appearance")
                }

                Section {
                    TextEditor(text: $userAgent)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .font(.monospaced(.custom("", size: 14.0, relativeTo: .body))())
                        .frame(height: 120)
                        .scrollIndicators(.never)
                } header: {
                    Text("UserAgent")
                } footer: {
                    Text("About.UserAgent.Tokens")
                }

                ViewportPickerSection(viewport: $viewport)

                Section {
                    TextField("Presets.Editor.SourceURL", text: $source)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                } header: {
                    Text("Presets.Detail.References")
                }
            }
            .scrollContentBackground(.hidden)
            .gradientBackground()
            .navigationTitle(mode == .new ? "ViewTitle.Presets.New" : "ViewTitle.Presets.Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .cancel) {
                            dismiss()
                        }
                    } else {
                        Button("Shared.Cancel", role: .cancel) {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .confirm) {
                            savePreset()
                            dismiss()
                        }
                        .disabled(name.isEmpty)
                    } else {
                        Button {
                            savePreset()
                            dismiss()
                        } label: {
                            Text(mode == .new ? "Shared.Add" : "Shared.Save")
                        }
                        .disabled(name.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerView(selectedIcon: $imageName)
            }
            .onAppear {
                if let preset = editingPreset {
                    name = preset.name
                    imageName = preset.imageName
                    userAgent = preset.userAgent
                    source = preset.allSources.first ?? ""
                    viewport = preset.viewport
                }
            }
        }
    }

    private func savePreset() {
        if mode == .edit, let existing = editingPreset {
            var updated = existing
            updated.name = name
            updated.imageName = imageName
            updated.userAgent = userAgent
            updated.source = source.isEmpty ? nil : source
            updated.sources = nil
            updated.viewport = viewport
            presetStore.updatePreset(updated)
        } else {
            let newPreset = Preset(
                name: name,
                imageName: imageName,
                userAgent: userAgent,
                source: source.isEmpty ? nil : source,
                viewport: viewport,
                isBuiltIn: false
            )
            presetStore.addPreset(newPreset)
        }
    }
}

struct IconPickerView: View {

    @Environment(\.dismiss) var dismiss
    @Binding var selectedIcon: String

    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    static let browserIcons: [String] = [
        "Safari", "Chrome", "Edgeium", "EdgeHTML", "IE",
        "Apple", "Google", "Bing", "OpenAI", "Claude",
        "SonyPlaystation", "SonyPlaystation5", "Xbox"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Self.browserIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedIcon == icon
                                          ? Color.accentColor.opacity(0.2)
                                          : Color(.secondarySystemGroupedBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedIcon == icon
                                                    ? Color.accentColor
                                                    : Color.clear, lineWidth: 2)
                                    )
                                Image(icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                            }
                            .frame(height: 60)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .gradientBackground()
            .navigationTitle("Presets.IconPicker.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Shared.Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
