import Foundation

struct BackupData: Codable {

    var version: Int
    var timestamp: Date

    var globalUserAgent: String
    var globalViewport: String
    var siteSettings: [SiteSetting]
    var customPresets: [Preset]
    var hiddenPresetNames: [String]
    var builtInPresetOverrides: [String: Preset]
    var cachedUserAgentUpdates: [String: String]
    var autoRefreshEnabled: Bool

    var customIcons: [String: Data]

    init(
        version: Int = 1,
        timestamp: Date,
        globalUserAgent: String,
        globalViewport: String,
        siteSettings: [SiteSetting],
        customPresets: [Preset],
        hiddenPresetNames: [String],
        builtInPresetOverrides: [String: Preset],
        cachedUserAgentUpdates: [String: String],
        autoRefreshEnabled: Bool,
        customIcons: [String: Data]
    ) {
        self.version = version
        self.timestamp = timestamp
        self.globalUserAgent = globalUserAgent
        self.globalViewport = globalViewport
        self.siteSettings = siteSettings
        self.customPresets = customPresets
        self.hiddenPresetNames = hiddenPresetNames
        self.builtInPresetOverrides = builtInPresetOverrides
        self.cachedUserAgentUpdates = cachedUserAgentUpdates
        self.autoRefreshEnabled = autoRefreshEnabled
        self.customIcons = customIcons
    }
}

struct BackupFile: Identifiable, Hashable {
    var id: URL { url }
    let url: URL
    let timestamp: Date
}
