//
//  PresetUpdater.swift
//  Unagent
//

import Foundation

@Observable
class PresetUpdater {

    // jnrbsn/user-agents: a well-known, independently maintained list
    // of the latest user agent strings, auto-updated daily via GitHub Actions
    private static let remoteUserAgentsURL = URL(
        string: "https://jnrbsn.github.io/user-agents/user-agents.json"
    )!
    private static let cachedUpdatesKey = "CachedUserAgentUpdates"
    private static let lastUpdateCheckKey = "LastPresetUpdateCheck"

    var isChecking: Bool = false
    var lastUpdateCheck: Date? {
        defaults.object(forKey: Self.lastUpdateCheckKey) as? Date
    }
    var updateResult: UpdateResult?

    enum UpdateResult: Equatable {
        case updated(count: Int)
        case noUpdates
        case failed(String)
    }

    func checkForUpdates() async {
        isChecking = true
        updateResult = nil

        do {
            let (data, response) = try await URLSession.shared.data(from: Self.remoteUserAgentsURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                updateResult = .failed(
                    NSLocalizedString("Presets.Update.Error.Server", comment: "")
                )
                isChecking = false
                return
            }

            let remoteUserAgents = try JSONDecoder().decode([String].self, from: data)
            let updatedCount = applyRemoteUserAgents(remoteUserAgents)

            defaults.set(Date(), forKey: Self.lastUpdateCheckKey)
            defaults.synchronize()

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

    // MARK: - Parsing & Matching

    private func applyRemoteUserAgents(_ remoteUserAgents: [String]) -> Int {
        guard let bundleURL = Bundle.main.url(forResource: "Presets", withExtension: "json"),
              let bundleData = try? Data(contentsOf: bundleURL),
              let bundledPresets = try? JSONDecoder().decode([Preset].self, from: bundleData) else {
            return 0
        }

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

        if let data = try? JSONEncoder().encode(updates),
           let jsonString = String(data: data, encoding: .utf8) {
            defaults.set(jsonString, forKey: Self.cachedUpdatesKey)
            defaults.synchronize()
        }

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

    // MARK: - Cache

    static func loadCachedUpdates() -> [String: String]? {
        guard let jsonString = defaults.string(forKey: cachedUpdatesKey),
              let jsonData = jsonString.data(using: .utf8),
              let updates = try? JSONDecoder().decode([String: String].self, from: jsonData) else {
            return nil
        }
        return updates
    }
}
