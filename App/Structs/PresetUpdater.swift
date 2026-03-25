//
//  PresetUpdater.swift
//  Unagent
//

import Foundation

@Observable
class PresetUpdater {

    // microlinkhq/top-user-agents: a well-known, independently maintained list
    // of the most common user agent strings from real-world traffic data,
    // updated weekly from 300M+ monthly requests
    private static let remoteUserAgentsURL = URL(
        string: "https://microlink.io/user-agents.json"
    )!
    private static let cachedUpdatesKey = "CachedUserAgentUpdates"
    private static let lastUpdateCheckKey = "LastPresetUpdateCheck"

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

        do {
            let remoteUserAgents = try await fetchRemoteUserAgents()
            pendingUpdates = computePendingUpdates(from: remoteUserAgents)
            defaults.set(Date(), forKey: Self.lastUpdateCheckKey)
            defaults.synchronize()
        } catch {
            // Silently fail on background check
        }

        isChecking = false
    }

    /// Check for updates and apply immediately (manual refresh from Presets tab)
    func checkForUpdates() async {
        isChecking = true
        updateResult = nil

        do {
            let remoteUserAgents = try await fetchRemoteUserAgents()
            let updatedCount = applyRemoteUserAgents(remoteUserAgents)

            defaults.set(Date(), forKey: Self.lastUpdateCheckKey)
            defaults.synchronize()

            pendingUpdates.removeAll()

            if updatedCount > 0 {
                updateResult = .updated(count: updatedCount)
            } else {
                updateResult = .noUpdates
            }
        } catch {
            updateResult = .failed(error.localizedDescription)
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

    // MARK: - Networking

    private func fetchRemoteUserAgents() async throws -> [String] {
        let (data, response) = try await URLSession.shared.data(from: Self.remoteUserAgentsURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([String].self, from: data)
    }

    // MARK: - Pending Updates Computation

    private func computePendingUpdates(from remoteUserAgents: [String]) -> [PendingPresetUpdate] {
        guard let bundledPresets = loadBundledPresets() else { return [] }
        let cachedUpdates = Self.loadCachedUpdates() ?? [:]
        var pending: [PendingPresetUpdate] = []
        var seenPresets: Set<String> = []

        for userAgent in remoteUserAgents {
            guard let match = identifyBrowser(from: userAgent) else { continue }

            for preset in bundledPresets {
                guard shouldUpdate(preset: preset, with: match),
                      !seenPresets.contains(preset.name) else { continue }

                let currentUA = cachedUpdates[preset.name] ?? preset.userAgent
                if currentUA != userAgent {
                    let currentVersion = extractVersion(
                        from: currentUA, for: match.browser
                    ) ?? "?"
                    let updatedVersion = extractVersion(
                        from: userAgent, for: match.browser
                    ) ?? "?"

                    pending.append(PendingPresetUpdate(
                        presetName: preset.name,
                        imageName: preset.imageName,
                        currentVersion: currentVersion,
                        updatedVersion: updatedVersion,
                        updatedUserAgent: userAgent
                    ))
                    seenPresets.insert(preset.name)
                }
            }
        }

        return pending
    }

    // MARK: - Parsing & Matching

    private func applyRemoteUserAgents(_ remoteUserAgents: [String]) -> Int {
        guard let bundledPresets = loadBundledPresets() else { return 0 }

        var updates: [String: String] = Self.loadCachedUpdates() ?? [:]
        var changedCount = 0

        for userAgent in remoteUserAgents {
            guard let match = identifyBrowser(from: userAgent) else { continue }

            for preset in bundledPresets {
                guard shouldUpdate(preset: preset, with: match) else { continue }

                let currentUA = updates[preset.name] ?? preset.userAgent
                if currentUA != userAgent {
                    updates[preset.name] = userAgent
                    changedCount += 1
                }
            }
        }

        saveCachedUpdates(updates)

        return changedCount
    }

    private struct BrowserMatch {
        let browser: Browser
        let platform: Platform
        let version: String

        enum Browser: String {
            case chrome, edge, safari, firefox
        }

        enum Platform: String {
            case macOS, windows, linux, android
        }
    }

    private func identifyBrowser(from userAgent: String) -> BrowserMatch? {
        let platform: BrowserMatch.Platform
        if userAgent.contains("Macintosh") {
            platform = .macOS
        } else if userAgent.contains("Windows") {
            platform = .windows
        } else if userAgent.contains("Android") {
            platform = .android
        } else if userAgent.contains("Linux") {
            platform = .linux
        } else {
            return nil
        }

        // Edge must be checked before Chrome (Edge UA contains "Chrome")
        if let range = userAgent.range(of: #"Edg/(\d+)"#, options: .regularExpression) {
            let versionStr = userAgent[range].replacingOccurrences(of: "Edg/", with: "")
            return BrowserMatch(browser: .edge, platform: platform, version: versionStr)
        }

        if userAgent.contains("Firefox/") {
            if let range = userAgent.range(of: #"Firefox/(\d+)"#, options: .regularExpression) {
                let versionStr = userAgent[range].replacingOccurrences(of: "Firefox/", with: "")
                return BrowserMatch(browser: .firefox, platform: platform, version: versionStr)
            }
        }

        if userAgent.contains("Chrome/") && !userAgent.contains("Edg") {
            if let range = userAgent.range(of: #"Chrome/(\d+)"#, options: .regularExpression) {
                let versionStr = userAgent[range].replacingOccurrences(of: "Chrome/", with: "")
                return BrowserMatch(browser: .chrome, platform: platform, version: versionStr)
            }
        }

        if userAgent.contains("Safari/") && userAgent.contains("Version/")
            && !userAgent.contains("Chrome") && !userAgent.contains("Edg") {
            if let range = userAgent.range(of: #"Version/(\d+)"#, options: .regularExpression) {
                let versionStr = userAgent[range].replacingOccurrences(of: "Version/", with: "")
                return BrowserMatch(browser: .safari, platform: platform, version: versionStr)
            }
        }

        return nil
    }

    private func shouldUpdate(preset: Preset, with match: BrowserMatch) -> Bool {
        let name = preset.name.lowercased()

        switch match.browser {
        case .chrome:
            guard name.contains("chrome") else { return false }
            // Only update macOS and Android desktop variants (iOS uses OS version tokens)
            if match.platform == .macOS && name.contains("macos") { return true }
            if match.platform == .android && name.contains("android") { return true }
        case .edge:
            guard name.contains("edge") && !name.contains("edgehtml") else { return false }
            if match.platform == .macOS && name.contains("macos") { return true }
            if match.platform == .android && name.contains("android") { return true }
        case .safari:
            guard name.contains("safari") && match.platform == .macOS
                    && name.contains("macos") else { return false }
            return true
        case .firefox:
            // App doesn't have Firefox presets currently, but support future additions
            guard name.contains("firefox") else { return false }
            if match.platform == .macOS && name.contains("macos") { return true }
        }

        return false
    }

    private func extractVersion(from userAgent: String, for browser: BrowserMatch.Browser) -> String? {
        switch browser {
        case .chrome:
            if let range = userAgent.range(of: #"Chrome/(\d+)"#, options: .regularExpression) {
                return String(userAgent[range].dropFirst("Chrome/".count))
            }
        case .edge:
            if let range = userAgent.range(of: #"Edg/(\d+)"#, options: .regularExpression) {
                return String(userAgent[range].dropFirst("Edg/".count))
            }
            if let range = userAgent.range(of: #"EdgA/(\d+)"#, options: .regularExpression) {
                return String(userAgent[range].dropFirst("EdgA/".count))
            }
        case .safari:
            if let range = userAgent.range(of: #"Version/(\d+)"#, options: .regularExpression) {
                return String(userAgent[range].dropFirst("Version/".count))
            }
        case .firefox:
            if let range = userAgent.range(of: #"Firefox/(\d+)"#, options: .regularExpression) {
                return String(userAgent[range].dropFirst("Firefox/".count))
            }
        }
        return nil
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
