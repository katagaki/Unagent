//
//  PresetCategory.swift
//  Unagent
//
//  Grouping for built-in presets. The raw value matches the "category"
//  key in Presets.json; allCases defines the display order of sections.
//

import Foundation

enum PresetCategory: String, CaseIterable, Identifiable {
    case browsers
    case apps
    case searchEngines
    case aiCrawlers
    case consoles
    case devices
    case legacy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .browsers: NSLocalizedString("Presets.Category.Browsers", comment: "")
        case .apps: NSLocalizedString("Presets.Category.Apps", comment: "")
        case .searchEngines: NSLocalizedString("Presets.Category.SearchEngines", comment: "")
        case .aiCrawlers: NSLocalizedString("Presets.Category.AICrawlers", comment: "")
        case .consoles: NSLocalizedString("Presets.Category.Consoles", comment: "")
        case .devices: NSLocalizedString("Presets.Category.Devices", comment: "")
        case .legacy: NSLocalizedString("Presets.Category.Legacy", comment: "")
        }
    }
}

extension Preset {
    /// The strongly-typed category for this preset, if it maps to a known one.
    var resolvedCategory: PresetCategory? {
        guard let category else { return nil }
        return PresetCategory(rawValue: category)
    }
}
