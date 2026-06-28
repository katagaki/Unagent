import Foundation

// Which JS surface browser-emulation.js installs for a preset. nil (absent) means
// auto-detect from the User-Agent — the extension's default behaviour.
enum Emulation: String, Codable, CaseIterable {
    case off = "none"          // "Don't Emulate" (case name avoids Optional.none clash)
    case chromium = "chromium"
    case safari = "safari"
    case firefox = "firefox"

    var displayName: String {
        return NSLocalizedString("Emulation.\(self.rawValue)", comment: "")
    }
}
