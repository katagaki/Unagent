//
//  PresetUpdater.swift
//  Unagent
//

import Foundation

@Observable
class PresetUpdater {

    private static let cachedUpdatesKey = "CachedUserAgentUpdates"
    private static let lastUpdateCheckKey = "LastPresetUpdateCheck"

    // iOS app mappings for App Store version lookups
    private struct iOSAppMapping {
        let presetNamePrefix: String
        let appStoreId: String
        let versionPattern: String  // regex to match version in UA string
        let versionPrefix: String   // prefix before version number (e.g. "CriOS/")
    }

    private static let iOSAppMappings: [iOSAppMapping] = [
        .init(presetNamePrefix: "Google Chrome", appStoreId: "535886823",
              versionPattern: #"CriOS/[0-9.]+"#, versionPrefix: "CriOS/"),
        .init(presetNamePrefix: "Microsoft Edge", appStoreId: "1288723196",
              versionPattern: #"EdgiOS/[0-9.]+"#, versionPrefix: "EdgiOS/"),
        .init(presetNamePrefix: "Google App", appStoreId: "284815942",
              versionPattern: #"GSA/[0-9.]+"#, versionPrefix: "GSA/"),
    ]

    // berstend/chrome-versions: Chrome stable release versions per platform
    private static let chromeVersionsURL = URL(
        string: "https://cdn.jsdelivr.net/gh/berstend/chrome-versions/data/stable/all/version/latest.json"
    )!

    private struct ChromeVersionEntry: Codable {
        let version: String
        let milestone: Int
    }

    private static let chromePlatformMappings: [(jsonKey: String, presetPlatform: String)] = [
        ("mac", "(macOS)"),
        ("android", "(Android)"),
    ]

    // Microsoft Edge stable release notes page
    private static let edgeReleaseNotesURL = URL(
        string: "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-relnote-stable-channel"
    )!
    // Edge mobile stable release notes page
    private static let edgeMobileReleaseNotesURL = URL(
        string: "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-relnote-mobile-stable-channel"
    )!

    var isChecking: Bool = false
    var lastUpdateCheck: Date? {
        defaults.object(forKey: Self.lastUpdateCheckKey) as? Date
    }
    var updateResult: UpdateResult?
    var pendingUpdates: [PendingPresetUpdate] = []

    enum UpdateResult: Equatable {
        case updated(count: Int)
        case noUpdates
        case failed(String)
    }

    struct PendingPresetUpdate: Identifiable {
        var id: String { presetName }
        let presetName: String
        let imageName: String
        let currentVersion: String
        let updatedVersion: String
        let updatedUserAgent: String
    }

    // MARK: - Public API

    /// Check for updates silently on app launch — populates pendingUpdates without applying
    func checkForUpdatesQuietly() async {
        isChecking = true

        var allPending: [PendingPresetUpdate] = []

        // iOS updates from App Store versions
        let iosPending = await computeIOSPendingUpdates()
        allPending.append(contentsOf: iosPending)

        // Chrome stable release versions (macOS, Android)
        let chromePending = await computeChromePendingUpdates()
        allPending.append(contentsOf: chromePending)

        // Edge stable release versions (macOS, Android, iOS)
        let edgePending = await computeEdgePendingUpdates()
        allPending.append(contentsOf: edgePending)

        // Deduplicate by preset name (later sources take priority)
        var seen: Set<String> = []
        pendingUpdates = allPending.reversed().filter { seen.insert($0.presetName).inserted }.reversed()
        defaults.set(Date(), forKey: Self.lastUpdateCheckKey)
        defaults.synchronize()

        isChecking = false
    }

    /// Check for updates and apply immediately (manual refresh from Presets tab)
    func checkForUpdates() async {
        isChecking = true
        updateResult = nil

        var totalUpdated = 0

        // iOS updates from App Store versions
        totalUpdated += await applyIOSUpdates()

        // Chrome stable release versions (macOS, Android)
        totalUpdated += await applyChromeUpdates()

        // Edge stable release versions (macOS, Android, iOS)
        totalUpdated += await applyEdgeUpdates()

        defaults.set(Date(), forKey: Self.lastUpdateCheckKey)
        defaults.synchronize()

        pendingUpdates.removeAll()

        if totalUpdated > 0 {
            updateResult = .updated(count: totalUpdated)
        } else {
            updateResult = .noUpdates
        }

        isChecking = false
    }

    /// Apply all pending updates to the cache
    func applyAllPendingUpdates() {
        var updates: [String: String] = Self.loadCachedUpdates() ?? [:]
        for pending in pendingUpdates {
            updates[pending.presetName] = pending.updatedUserAgent
        }
        saveCachedUpdates(updates)
        pendingUpdates.removeAll()
    }

    /// Apply a single pending update to the cache
    func applyUpdate(_ update: PendingPresetUpdate) {
        var updates: [String: String] = Self.loadCachedUpdates() ?? [:]
        updates[update.presetName] = update.updatedUserAgent
        saveCachedUpdates(updates)
        pendingUpdates.removeAll { $0.id == update.id }
    }

    // MARK: - App Store Lookup

    private struct iTunesLookupResponse: Codable {
        let resultCount: Int
        let results: [iTunesLookupResult]
    }

    private struct iTunesLookupResult: Codable {
        let version: String
    }

    private func fetchAppStoreVersion(appId: String) async throws -> String {
        let url = URL(string: "https://itunes.apple.com/lookup?id=\(appId)")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(iTunesLookupResponse.self, from: data)
        guard let app = result.results.first else {
            throw URLError(.resourceUnavailable)
        }
        return app.version
    }

    /// Fetch all iOS app versions concurrently, returning a map of appStoreId → version
    private func fetchAllAppStoreVersions() async -> [String: String] {
        await withTaskGroup(of: (String, String?).self) { group in
            for mapping in Self.iOSAppMappings {
                group.addTask {
                    let version = try? await self.fetchAppStoreVersion(appId: mapping.appStoreId)
                    return (mapping.appStoreId, version)
                }
            }
            var versions: [String: String] = [:]
            for await (appId, version) in group {
                if let version { versions[appId] = version }
            }
            return versions
        }
    }

    // MARK: - Chrome Versions Lookup

    private func fetchChromeVersions() async throws -> [String: ChromeVersionEntry] {
        let (data, response) = try await URLSession.shared.data(from: Self.chromeVersionsURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([String: ChromeVersionEntry].self, from: data)
    }

    // MARK: - Chrome Pending Updates

    private func computeChromePendingUpdates() async -> [PendingPresetUpdate] {
        guard let bundledPresets = loadBundledPresets(),
              let chromeVersions = try? await fetchChromeVersions() else { return [] }
        let cachedUpdates = Self.loadCachedUpdates() ?? [:]
        var pending: [PendingPresetUpdate] = []

        for (jsonKey, presetPlatform) in Self.chromePlatformMappings {
            guard let entry = chromeVersions[jsonKey] else { continue }

            for preset in bundledPresets where
                preset.name.hasPrefix("Google Chrome") &&
                preset.name.contains(presetPlatform) {

                let currentUA = cachedUpdates[preset.name] ?? preset.userAgent
                let updatedUA = currentUA.replacingOccurrences(
                    of: #"Chrome/[0-9.]+"#,
                    with: "Chrome/\(entry.version)",
                    options: .regularExpression
                )

                guard currentUA != updatedUA else { continue }

                let currentVersion = extractMobileVersion(
                    from: currentUA, prefix: "Chrome/"
                ) ?? "?"

                pending.append(PendingPresetUpdate(
                    presetName: preset.name,
                    imageName: preset.imageName,
                    currentVersion: currentVersion,
                    updatedVersion: String(entry.milestone),
                    updatedUserAgent: updatedUA
                ))
            }
        }

        return pending
    }

    private func applyChromeUpdates() async -> Int {
        guard let bundledPresets = loadBundledPresets(),
              let chromeVersions = try? await fetchChromeVersions() else { return 0 }
        var updates: [String: String] = Self.loadCachedUpdates() ?? [:]
        var changedCount = 0

        for (jsonKey, presetPlatform) in Self.chromePlatformMappings {
            guard let entry = chromeVersions[jsonKey] else { continue }

            for preset in bundledPresets where
                preset.name.hasPrefix("Google Chrome") &&
                preset.name.contains(presetPlatform) {

                let currentUA = updates[preset.name] ?? preset.userAgent
                let updatedUA = currentUA.replacingOccurrences(
                    of: #"Chrome/[0-9.]+"#,
                    with: "Chrome/\(entry.version)",
                    options: .regularExpression
                )

                if currentUA != updatedUA {
                    updates[preset.name] = updatedUA
                    changedCount += 1
                }
            }
        }

        saveCachedUpdates(updates)
        return changedCount
    }

    // MARK: - Edge Version Scraping

    /// Scrape the latest stable Edge version from Microsoft's release notes page.
    /// Looks for the first h2 heading matching "Version X.X.X.X: ... (Stable)".
    private func fetchEdgeVersion(from url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }

        // Match: Version 146.0.3856.59: ... (Stable)
        let pattern = #"Version\s+(\d+\.\d+\.\d+\.\d+):[^(]*\(Stable\)"#
        guard let range = html.range(of: pattern, options: .regularExpression),
              let versionRange = html[range].range(
                  of: #"\d+\.\d+\.\d+\.\d+"#, options: .regularExpression
              ) else {
            throw URLError(.resourceUnavailable)
        }

        return String(html[versionRange])
    }

    /// Fetch Edge desktop and mobile versions concurrently
    private func fetchEdgeVersions() async -> (desktop: String?, mobile: String?) {
        async let desktopVersion = try? fetchEdgeVersion(from: Self.edgeReleaseNotesURL)
        async let mobileVersion = try? fetchEdgeVersion(from: Self.edgeMobileReleaseNotesURL)
        return await (desktopVersion, mobileVersion)
    }

    // MARK: - Edge Pending Updates

    private func computeEdgePendingUpdates() async -> [PendingPresetUpdate] {
        guard let bundledPresets = loadBundledPresets() else { return [] }
        let cachedUpdates = Self.loadCachedUpdates() ?? [:]
        let edgeVersions = await fetchEdgeVersions()
        var pending: [PendingPresetUpdate] = []

        let platforms: [(version: String?, platform: String, versionPattern: String, versionPrefix: String)] = [
            (edgeVersions.desktop, "(macOS)", #"Edg/[0-9.]+"#, "Edg/"),
            (edgeVersions.mobile, "(Android)", #"EdgA/[0-9.]+"#, "EdgA/"),
            (edgeVersions.mobile, "(iOS)", #"EdgiOS/[0-9.]+"#, "EdgiOS/"),
        ]

        for (version, platform, versionPattern, versionPrefix) in platforms {
            guard let version else { continue }

            for preset in bundledPresets where
                preset.name.hasPrefix("Microsoft Edge") &&
                !preset.name.contains("EdgeHTML") &&
                preset.name.contains(platform) {

                let currentUA = cachedUpdates[preset.name] ?? preset.userAgent
                let updatedUA = currentUA.replacingOccurrences(
                    of: versionPattern,
                    with: "\(versionPrefix)\(version)",
                    options: .regularExpression
                )

                guard currentUA != updatedUA else { continue }

                let currentVersion = extractMobileVersion(
                    from: currentUA, prefix: versionPrefix
                ) ?? "?"
                let updatedVersion = version.components(separatedBy: ".").first ?? "?"

                pending.append(PendingPresetUpdate(
                    presetName: preset.name,
                    imageName: preset.imageName,
                    currentVersion: currentVersion,
                    updatedVersion: updatedVersion,
                    updatedUserAgent: updatedUA
                ))
            }
        }

        return pending
    }

    private func applyEdgeUpdates() async -> Int {
        guard let bundledPresets = loadBundledPresets() else { return 0 }
        var updates: [String: String] = Self.loadCachedUpdates() ?? [:]
        let edgeVersions = await fetchEdgeVersions()
        var changedCount = 0

        let platforms: [(version: String?, platform: String, versionPattern: String, versionPrefix: String)] = [
            (edgeVersions.desktop, "(macOS)", #"Edg/[0-9.]+"#, "Edg/"),
            (edgeVersions.mobile, "(Android)", #"EdgA/[0-9.]+"#, "EdgA/"),
            (edgeVersions.mobile, "(iOS)", #"EdgiOS/[0-9.]+"#, "EdgiOS/"),
        ]

        for (version, platform, versionPattern, versionPrefix) in platforms {
            guard let version else { continue }

            for preset in bundledPresets where
                preset.name.hasPrefix("Microsoft Edge") &&
                !preset.name.contains("EdgeHTML") &&
                preset.name.contains(platform) {

                let currentUA = updates[preset.name] ?? preset.userAgent
                let updatedUA = currentUA.replacingOccurrences(
                    of: versionPattern,
                    with: "\(versionPrefix)\(version)",
                    options: .regularExpression
                )

                if currentUA != updatedUA {
                    updates[preset.name] = updatedUA
                    changedCount += 1
                }
            }
        }

        saveCachedUpdates(updates)
        return changedCount
    }

    // MARK: - iOS Pending Updates

    private func computeIOSPendingUpdates() async -> [PendingPresetUpdate] {
        guard let bundledPresets = loadBundledPresets() else { return [] }
        let cachedUpdates = Self.loadCachedUpdates() ?? [:]
        let appStoreVersions = await fetchAllAppStoreVersions()
        var pending: [PendingPresetUpdate] = []

        for mapping in Self.iOSAppMappings {
            guard let version = appStoreVersions[mapping.appStoreId] else { continue }

            for preset in bundledPresets where
                preset.name.hasPrefix(mapping.presetNamePrefix) &&
                preset.name.contains("(iOS)") {

                let currentUA = cachedUpdates[preset.name] ?? preset.userAgent
                let updatedUA = currentUA.replacingOccurrences(
                    of: mapping.versionPattern,
                    with: "\(mapping.versionPrefix)\(version)",
                    options: .regularExpression
                )

                guard currentUA != updatedUA else { continue }

                let currentVersion = extractMobileVersion(
                    from: currentUA, prefix: mapping.versionPrefix
                ) ?? "?"
                let updatedVersion = version.components(separatedBy: ".").first ?? "?"

                pending.append(PendingPresetUpdate(
                    presetName: preset.name,
                    imageName: preset.imageName,
                    currentVersion: currentVersion,
                    updatedVersion: updatedVersion,
                    updatedUserAgent: updatedUA
                ))
            }
        }

        return pending
    }

    private func applyIOSUpdates() async -> Int {
        guard let bundledPresets = loadBundledPresets() else { return 0 }
        var updates: [String: String] = Self.loadCachedUpdates() ?? [:]
        let appStoreVersions = await fetchAllAppStoreVersions()
        var changedCount = 0

        for mapping in Self.iOSAppMappings {
            guard let version = appStoreVersions[mapping.appStoreId] else { continue }

            for preset in bundledPresets where
                preset.name.hasPrefix(mapping.presetNamePrefix) &&
                preset.name.contains("(iOS)") {

                let currentUA = updates[preset.name] ?? preset.userAgent
                let updatedUA = currentUA.replacingOccurrences(
                    of: mapping.versionPattern,
                    with: "\(mapping.versionPrefix)\(version)",
                    options: .regularExpression
                )

                if currentUA != updatedUA {
                    updates[preset.name] = updatedUA
                    changedCount += 1
                }
            }
        }

        saveCachedUpdates(updates)
        return changedCount
    }

    // MARK: - Version Extraction Helpers

    private func extractMobileVersion(from userAgent: String, prefix: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: prefix)
        let pattern = "\(escaped)(\\d+)"
        guard let range = userAgent.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        return String(userAgent[range].dropFirst(prefix.count))
    }

    // MARK: - Helpers

    private func loadBundledPresets() -> [Preset]? {
        guard let url = Bundle.main.url(forResource: "Presets", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let presets = try? JSONDecoder().decode([Preset].self, from: data) else {
            return nil
        }
        return presets
    }

    // MARK: - Cache

    static func loadCachedUpdates() -> [String: String]? {
        guard let jsonString = defaults.string(forKey: cachedUpdatesKey),
              let jsonData = jsonString.data(using: .utf8),
              let updates = try? JSONDecoder().decode([String: String].self, from: jsonData) else {
            return nil
        }
        return updates
    }

    private func saveCachedUpdates(_ updates: [String: String]) {
        if let data = try? JSONEncoder().encode(updates),
           let jsonString = String(data: data, encoding: .utf8) {
            defaults.set(jsonString, forKey: Self.cachedUpdatesKey)
            defaults.synchronize()
        }
    }
}
