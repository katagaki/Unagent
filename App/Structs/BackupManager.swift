import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum BackupManager {

    static let ubiquityContainerID = "iCloud.com.tsubuzaki.BingBong"

    private enum Key {
        static let globalUserAgent = "UserAgent"
        static let globalViewport = "GlobalViewport"
        static let siteSettings = "SiteSettings"
        static let customPresets = "CustomPresets"
        static let hiddenPresets = "HiddenBuiltInPresets"
        static let hiddenPresetsInitialized = "HiddenBuiltInPresetsInitialized"
        static let builtInPresetOverrides = "BuiltInPresetOverrides"
        static let cachedUpdates = "CachedUserAgentUpdates"
        static let autoRefreshEnabled = "AutoRefreshEnabled"
        static let shouldExtensionUpdate = "ShouldExtensionUpdate"
    }

    enum RestoreStrategy {
        case merge
        case overwrite
    }

    enum BackupError: LocalizedError {
        case iCloudUnavailable
        case readFailed
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .iCloudUnavailable:
                return NSLocalizedString("Backup.Error.iCloudUnavailable", comment: "")
            case .readFailed:
                return NSLocalizedString("Backup.Error.ReadFailed", comment: "")
            case .encodingFailed:
                return NSLocalizedString("Backup.Error.EncodingFailed", comment: "")
            }
        }
    }

    // MARK: - Snapshot

    static func snapshot(timestamp: Date) -> BackupData {
        let customPresets = decodeStringValue([Preset].self, forKey: Key.customPresets) ?? []

        var icons: [String: Data] = [:]
        for preset in customPresets where CustomIconStore.isCustomIcon(preset.imageName) {
            let url = CustomIconStore.url(for: preset.imageName)
            if let data = try? Data(contentsOf: url) {
                icons[preset.imageName] = data
            }
        }

        return BackupData(
            timestamp: timestamp,
            globalUserAgent: defaults.string(forKey: Key.globalUserAgent) ?? "",
            globalViewport: defaults.string(forKey: Key.globalViewport) ?? "",
            siteSettings: decodeStringValue([SiteSetting].self, forKey: Key.siteSettings) ?? [],
            customPresets: customPresets,
            hiddenPresetNames: defaults.stringArray(forKey: Key.hiddenPresets) ?? [],
            builtInPresetOverrides: decodeStringValue([String: Preset].self, forKey: Key.builtInPresetOverrides) ?? [:],
            cachedUserAgentUpdates: decodeStringValue([String: String].self, forKey: Key.cachedUpdates) ?? [:],
            autoRefreshEnabled: defaults.bool(forKey: Key.autoRefreshEnabled),
            customIcons: icons
        )
    }

    // MARK: - Restore

    static func restore(_ backup: BackupData, strategy: RestoreStrategy) {
        for (filename, data) in backup.customIcons {
            try? data.write(to: CustomIconStore.url(for: filename))
        }

        switch strategy {
        case .overwrite:
            defaults.set(backup.globalUserAgent, forKey: Key.globalUserAgent)
            defaults.set(backup.globalViewport, forKey: Key.globalViewport)
            encodeStringValue(backup.siteSettings, forKey: Key.siteSettings)
            encodeStringValue(backup.customPresets, forKey: Key.customPresets)
            defaults.set(backup.hiddenPresetNames, forKey: Key.hiddenPresets)
            encodeStringValue(backup.builtInPresetOverrides, forKey: Key.builtInPresetOverrides)
            encodeStringValue(backup.cachedUserAgentUpdates, forKey: Key.cachedUpdates)
            defaults.set(backup.autoRefreshEnabled, forKey: Key.autoRefreshEnabled)

        case .merge:
            if !backup.globalUserAgent.isEmpty {
                defaults.set(backup.globalUserAgent, forKey: Key.globalUserAgent)
            }
            if !backup.globalViewport.isEmpty {
                defaults.set(backup.globalViewport, forKey: Key.globalViewport)
            }
            encodeStringValue(mergedSiteSettings(backup.siteSettings), forKey: Key.siteSettings)
            encodeStringValue(mergedCustomPresets(backup.customPresets), forKey: Key.customPresets)

            let mergedHidden = Set(defaults.stringArray(forKey: Key.hiddenPresets) ?? [])
                .union(backup.hiddenPresetNames)
            defaults.set(Array(mergedHidden), forKey: Key.hiddenPresets)

            var overrides = decodeStringValue([String: Preset].self, forKey: Key.builtInPresetOverrides) ?? [:]
            backup.builtInPresetOverrides.forEach { overrides[$0.key] = $0.value }
            encodeStringValue(overrides, forKey: Key.builtInPresetOverrides)

            var updates = decodeStringValue([String: String].self, forKey: Key.cachedUpdates) ?? [:]
            backup.cachedUserAgentUpdates.forEach { updates[$0.key] = $0.value }
            encodeStringValue(updates, forKey: Key.cachedUpdates)

            if backup.autoRefreshEnabled {
                defaults.set(true, forKey: Key.autoRefreshEnabled)
            }
        }

        defaults.set(true, forKey: Key.hiddenPresetsInitialized)
        defaults.set(true, forKey: Key.shouldExtensionUpdate)
        defaults.synchronize()
    }

    private static func mergedSiteSettings(_ incoming: [SiteSetting]) -> [SiteSetting] {
        let existing = decodeStringValue([SiteSetting].self, forKey: Key.siteSettings) ?? []
        var byDomain: [String: SiteSetting] = [:]
        var order: [String] = []
        for setting in existing {
            if byDomain[setting.domain] == nil { order.append(setting.domain) }
            byDomain[setting.domain] = setting
        }
        for setting in incoming {
            if byDomain[setting.domain] == nil { order.append(setting.domain) }
            byDomain[setting.domain] = setting
        }
        return order.compactMap { byDomain[$0] }
    }

    private static func mergedCustomPresets(_ incoming: [Preset]) -> [Preset] {
        let existing = decodeStringValue([Preset].self, forKey: Key.customPresets) ?? []
        var byID: [UUID: Preset] = [:]
        var order: [UUID] = []
        for preset in existing {
            if byID[preset.id] == nil { order.append(preset.id) }
            byID[preset.id] = preset
        }
        for preset in incoming {
            if byID[preset.id] == nil { order.append(preset.id) }
            byID[preset.id] = preset
        }
        return order.compactMap { byID[$0] }
    }

    // MARK: - Encoding

    static func encode(_ backup: BackupData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> BackupData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupData.self, from: data)
    }

    // MARK: - File Naming

    static func fileName(for date: Date) -> String {
        "Unagent-\(timestampString(for: date)).json"
    }

    static func defaultExportName(for date: Date) -> String {
        "Unagent-\(timestampString(for: date))"
    }

    private static func timestampString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: date)
    }

    private static func timestamp(fromFileName name: String) -> Date? {
        guard name.hasPrefix("Unagent-"), name.hasSuffix(".json") else { return nil }
        let stamp = name.dropFirst("Unagent-".count).dropLast(".json".count)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.date(from: String(stamp))
    }

    // MARK: - iCloud

    static var isiCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private static func iCloudDocumentsURL() async -> URL? {
        await Task.detached(priority: .userInitiated) {
            guard let container = FileManager.default.url(
                forUbiquityContainerIdentifier: ubiquityContainerID
            ) else { return nil }
            let documents = container.appendingPathComponent("Documents", isDirectory: true)
            try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            return documents
        }.value
    }

    @discardableResult
    static func backUpToiCloud(timestamp: Date) async throws -> URL {
        let backup = snapshot(timestamp: timestamp)
        let data = try encode(backup)
        guard let documents = await iCloudDocumentsURL() else {
            throw BackupError.iCloudUnavailable
        }
        let url = documents.appendingPathComponent(fileName(for: timestamp))
        try writeCoordinated(data, to: url)
        return url
    }

    static func listiCloudBackups() async -> [BackupFile] {
        guard let documents = await iCloudDocumentsURL() else { return [] }
        let manager = FileManager.default
        guard let urls = try? manager.contentsOfDirectory(
            at: documents,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return urls
            .filter { $0.lastPathComponent.hasPrefix("Unagent-") && $0.pathExtension == "json" }
            .map { url in
                let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate
                let date = timestamp(fromFileName: url.lastPathComponent)
                    ?? modified
                    ?? Date(timeIntervalSince1970: 0)
                return BackupFile(url: url, timestamp: date)
            }
            .sorted { $0.timestamp > $1.timestamp }
    }

    static func loadBackup(at url: URL) async throws -> BackupData {
        try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        let data = try await Task.detached(priority: .userInitiated) {
            try readCoordinated(url)
        }.value
        return try decode(data)
    }

    // MARK: - Coordinated File I/O

    private static func writeCoordinated(_ data: Data, to url: URL) throws {
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var operationError: Error?
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { newURL in
            do {
                try data.write(to: newURL, options: .atomic)
            } catch {
                operationError = error
            }
        }
        if let coordinationError { throw coordinationError }
        if let operationError { throw operationError }
    }

    private static func readCoordinated(_ url: URL) throws -> Data {
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var operationError: Error?
        var result: Data?
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { newURL in
            do {
                result = try Data(contentsOf: newURL)
            } catch {
                operationError = error
            }
        }
        if let coordinationError { throw coordinationError }
        if let operationError { throw operationError }
        guard let result else { throw BackupError.readFailed }
        return result
    }

    // MARK: - UserDefaults JSON Helpers

    private static func decodeStringValue<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let jsonString = defaults.string(forKey: key),
              let data = jsonString.data(using: .utf8),
              let value = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return value
    }

    private static func encodeStringValue<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value),
           let jsonString = String(data: data, encoding: .utf8) {
            defaults.set(jsonString, forKey: key)
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
