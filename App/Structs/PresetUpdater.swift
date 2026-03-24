//
//  PresetUpdater.swift
//  Unagent
//

import Foundation

@Observable
class PresetUpdater {

    private static let remotePresetsURL = URL(
        string: "https://raw.githubusercontent.com/katagaki/Unagent/main/App/Presets.json"
    )!
    private static let cachedPresetsKey = "CachedRemotePresets"
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
            let (data, response) = try await URLSession.shared.data(from: Self.remotePresetsURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                updateResult = .failed(
                    NSLocalizedString("Presets.Update.Error.Server", comment: "")
                )
                isChecking = false
                return
            }

            let remotePresets = try JSONDecoder().decode([Preset].self, from: data)

            let updatedCount = applyRemotePresets(remotePresets, rawData: data)

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

    private func applyRemotePresets(_ remotePresets: [Preset], rawData: Data) -> Int {
        guard let bundleURL = Bundle.main.url(forResource: "Presets", withExtension: "json"),
              let bundleData = try? Data(contentsOf: bundleURL),
              let bundledPresets = try? JSONDecoder().decode([Preset].self, from: bundleData) else {
            return 0
        }

        let bundledByName = Dictionary(uniqueKeysWithValues: bundledPresets.map { ($0.name, $0) })
        var changedCount = 0

        for remotePreset in remotePresets {
            if let bundled = bundledByName[remotePreset.name] {
                if remotePreset.userAgent != bundled.userAgent {
                    changedCount += 1
                }
            } else {
                changedCount += 1
            }
        }

        if let jsonString = String(data: rawData, encoding: .utf8) {
            defaults.set(jsonString, forKey: Self.cachedPresetsKey)
            defaults.synchronize()
        }

        return changedCount
    }

    static func loadCachedRemotePresets() -> [Preset]? {
        guard let jsonString = defaults.string(forKey: cachedPresetsKey),
              let jsonData = jsonString.data(using: .utf8),
              let presets = try? JSONDecoder().decode([Preset].self, from: jsonData) else {
            return nil
        }
        return presets
    }
}
