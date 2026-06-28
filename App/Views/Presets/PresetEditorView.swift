import PhotosUI
import SwiftUI

struct PresetEditorView: View {

    @Environment(\.dismiss) var dismiss

    var mode: EditorMode
    var presetStore: PresetStore
    var editingPreset: Preset?

    @State private var name: String = ""
    @State private var imageName: String = "WebKit"
    @State private var userAgent: String = ""
    @State private var viewport: Viewport?
    @State private var emulation: Emulation? = Emulation.off
    @State private var photoItem: PhotosPickerItem?

    // Browser engines offered for custom presets (display name → icon asset).
    static let engineOptions: [(name: String, imageName: String)] = [
        ("WebKit", "WebKit"),
        ("Blink", "Chromium"),
        ("Gecko", "Gecko"),
        ("Trident", "IE"),
        ("Ladybird", "Ladybird")
    ]

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
                    Menu {
                        Picker("Presets.Editor.Icon", selection: $imageName) {
                            ForEach(Self.engineOptions, id: \.imageName) { option in
                                Label(option.name, image: option.imageName)
                                    .tag(option.imageName)
                            }
                        }
                    } label: {
                        HStack(spacing: 8.0) {
                            Text("Presets.Editor.Icon")
                            Spacer()
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24.0, height: 24.0)
                            Text(Self.engineOptions.first { $0.imageName == imageName }?.name ?? "")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Presets.Editor.ChoosePhoto", systemImage: "photo")
                    }
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

                EmulationPickerSection(emulation: $emulation)
            }
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
            .onChange(of: photoItem) {
                guard let photoItem else { return }
                Task {
                    if let data = try? await photoItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let filename = CustomIconStore.save(image) {
                        imageName = filename
                    }
                }
            }
            .onAppear {
                if let preset = editingPreset {
                    name = preset.name
                    imageName = preset.imageName
                    userAgent = preset.userAgent
                    viewport = preset.viewport
                    emulation = preset.emulation ?? Emulation.off
                }
            }
        }
    }

    private func savePreset() {
        if mode == .edit, let existing = editingPreset {
            var updated = existing
            updated.name = name
            updated.imageName = imageName
            // A picked custom icon should win over any remote store icon.
            if CustomIconStore.isCustomIcon(imageName) { updated.iconURL = nil }
            updated.userAgent = userAgent
            updated.viewport = viewport
            updated.emulation = emulation
            presetStore.updatePreset(updated)
        } else {
            let newPreset = Preset(
                name: name,
                imageName: imageName,
                userAgent: userAgent,
                viewport: viewport,
                emulation: emulation,
                isBuiltIn: false
            )
            presetStore.addPreset(newPreset)
        }
    }
}
