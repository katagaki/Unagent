//
//  PresetStore.swift
//  Unagent
//

import Foundation
import SwiftUI

@Observable
class PresetStore {

    private(set) var presets: [Preset] = []

    private let customPresetsKey = "CustomPresets"
    private let hiddenPresetsKey = "HiddenBuiltInPresets"
    private let hiddenPresetsInitializedKey = "HiddenBuiltInPresetsInitialized"

    private(set) var hiddenPresetNames: Set<String> = []

    init() {
        loadHiddenPresets()
        loadPresets()
    }

    func loadPresets() {
        var allPresets: [Preset] = []

        // Load built-in presets from JSON
        if let url = Bundle.main.url(forResource: "Presets", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           var builtIn = try? JSONDecoder().decode([Preset].self, from: data) {
            for i in builtIn.indices {
                builtIn[i].isBuiltIn = true
            }
            allPresets.append(contentsOf: builtIn)
        }

        // Load custom presets from UserDefaults
        if let jsonString = defaults.string(forKey: customPresetsKey),
           let jsonData = jsonString.data(using: .utf8),
           var custom = try? JSONDecoder().decode([Preset].self, from: jsonData) {
            for i in custom.indices {
                custom[i].isBuiltIn = false
            }
            allPresets.append(contentsOf: custom)
        }

        presets = allPresets
    }

    var builtInPresets: [Preset] {
        presets.filter { $0.isBuiltIn }
    }

    var customPresets: [Preset] {
        presets.filter { !$0.isBuiltIn }
    }

    func addPreset(_ preset: Preset) {
        var newPreset = preset
        newPreset.isBuiltIn = false
        presets.append(newPreset)
        saveCustomPresets()
    }

    func updatePreset(_ preset: Preset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            if preset.isBuiltIn {
                saveBuiltInOverrides(preset)
            } else {
                saveCustomPresets()
            }
        }
    }

    func deletePreset(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        if !preset.isBuiltIn {
            saveCustomPresets()
        }
    }

    private func saveCustomPresets() {
        let custom = presets.filter { !$0.isBuiltIn }
        if let data = try? JSONEncoder().encode(custom),
           let jsonString = String(data: data, encoding: .utf8) {
            defaults.set(jsonString, forKey: customPresetsKey)
            defaults.synchronize()
        }
    }

    private func saveBuiltInOverrides(_ preset: Preset) {
        // For built-in presets, we save edits to a separate overrides store
        var overrides = loadBuiltInOverrides()
        overrides[preset.id.uuidString] = preset
        if let data = try? JSONEncoder().encode(overrides),
           let jsonString = String(data: data, encoding: .utf8) {
            defaults.set(jsonString, forKey: "BuiltInPresetOverrides")
            defaults.synchronize()
        }
    }

    private func loadBuiltInOverrides() -> [String: Preset] {
        guard let jsonString = defaults.string(forKey: "BuiltInPresetOverrides"),
              let jsonData = jsonString.data(using: .utf8),
              let overrides = try? JSONDecoder().decode([String: Preset].self, from: jsonData) else {
            return [:]
        }
        return overrides
    }

    // MARK: - Hidden Built-In Presets

    private static let defaultVisiblePresetNames: Set<String> = [
        "Default (Don't Change)",
        "Safari (iOS)",
        "Safari (macOS)",
        "Microsoft Edge 144 (iOS)",
        "Microsoft Edge 144 (macOS)",
        "Google Chrome 145 (iOS)",
        "Google Chrome 144 (macOS)"
    ]

    private func loadHiddenPresets() {
        if defaults.bool(forKey: hiddenPresetsInitializedKey) {
            if let names = defaults.stringArray(forKey: hiddenPresetsKey) {
                hiddenPresetNames = Set(names)
            }
        } else {
            // First launch: hide all built-in presets except Safari, Edge, and Chrome for iOS/macOS
            if let url = Bundle.main.url(forResource: "Presets", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let builtIn = try? JSONDecoder().decode([Preset].self, from: data) {
                let allNames = Set(builtIn.map(\.name))
                hiddenPresetNames = allNames.subtracting(Self.defaultVisiblePresetNames)
            }
            defaults.set(true, forKey: hiddenPresetsInitializedKey)
            saveHiddenPresets()
        }
    }

    private func saveHiddenPresets() {
        defaults.set(Array(hiddenPresetNames), forKey: hiddenPresetsKey)
        defaults.synchronize()
    }

    func hideBuiltInPreset(_ preset: Preset) {
        hiddenPresetNames.insert(preset.name)
        saveHiddenPresets()
    }

    func unhideBuiltInPreset(name: String) {
        hiddenPresetNames.remove(name)
        saveHiddenPresets()
    }

    func unhideAllBuiltInPresets() {
        hiddenPresetNames.removeAll()
        saveHiddenPresets()
    }

    var visibleBuiltInPresets: [Preset] {
        builtInPresets.filter { !hiddenPresetNames.contains($0.name) }
    }
}
