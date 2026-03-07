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
    @State private var imageName: String = "globe"
    @State private var userAgent: String = ""
    @State private var source: String = ""
    @State private var viewport: Viewport? = nil
    @State private var isShowingIconPicker: Bool = false

    private static let systemIcons: [String] = [
        "globe", "network", "desktopcomputer", "laptopcomputer", "iphone",
        "ipad", "applewatch", "tv", "gamecontroller", "headphones",
        "antenna.radiowaves.left.and.right", "wifi", "bolt.fill", "shield.fill", "lock.fill",
        "eye.fill", "star.fill", "heart.fill", "bookmark.fill", "tag.fill",
        "flag.fill", "bell.fill", "paperplane.fill", "link", "doc.fill",
        "folder.fill", "tray.fill", "archivebox.fill", "externaldrive.fill", "cpu",
        "memorychip", "terminal.fill", "chevron.left.forwardslash.chevron.right", "hammer.fill", "wrench.fill",
        "gearshape.fill", "slider.horizontal.3", "gauge.with.dots.needle.33percent", "speedometer", "cloud.fill"
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
                    Button {
                        isShowingIconPicker = true
                    } label: {
                        HStack {
                            Text("Presets.Editor.Icon")
                            Spacer()
                            Image(systemName: imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.secondary)
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
                    Text("About.UserAgent")
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
            .navigationTitle(mode == .new ? "ViewTitle.Presets.New" : "ViewTitle.Presets.Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Shared.Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        savePreset()
                        dismiss()
                    } label: {
                        Text(mode == .new ? "Shared.Add" : "Shared.Save")
                    }
                    .disabled(name.isEmpty)
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

    private static let icons: [String] = [
        "globe", "network", "desktopcomputer", "laptopcomputer", "iphone",
        "ipad", "applewatch", "tv", "gamecontroller", "headphones",
        "antenna.radiowaves.left.and.right", "wifi", "bolt.fill", "shield.fill", "lock.fill",
        "eye.fill", "star.fill", "heart.fill", "bookmark.fill", "tag.fill",
        "flag.fill", "bell.fill", "paperplane.fill", "link", "doc.fill",
        "folder.fill", "tray.fill", "archivebox.fill", "externaldrive.fill", "cpu",
        "memorychip", "terminal.fill", "chevron.left.forwardslash.chevron.right", "hammer.fill", "wrench.fill",
        "gearshape.fill", "slider.horizontal.3", "gauge.with.dots.needle.33percent", "speedometer", "cloud.fill",
        "person.fill", "person.2.fill", "hand.raised.fill", "magnifyingglass", "camera.fill",
        "photo.fill", "video.fill", "music.note", "mic.fill", "location.fill",
        "map.fill", "safari", "app.fill", "command", "option",
        "power", "battery.100", "lightbulb.fill", "flame.fill", "drop.fill"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Self.icons, id: \.self) { icon in
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
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon
                                                     ? Color.accentColor
                                                     : .primary)
                            }
                            .frame(height: 60)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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
