import Foundation
import Observation

@Observable
final class ExtensionActivationMonitor {

    private(set) var isExtensionEnabled: Bool = false

    private(set) var hasWebsiteAccess: Bool = false

    var isFullySetUp: Bool { isExtensionEnabled && hasWebsiteAccess }

    private let enabledKey = "ExtensionEnabledLastSeen"
    private let websiteAccessKey = "ExtensionWebsiteAccessLastSeen"

    // iOS cannot detect "enabled" until the extension runs in Safari, so the
    // onboarding lets the user mark a step done manually. These flags persist
    // that choice alongside the auto-detected heartbeat.
    private let enabledConfirmedKey = "OnboardingEnableConfirmed"
    private let accessConfirmedKey = "OnboardingAccessConfirmed"

    init() {
        refresh()
    }

    func refresh() {
        let access = defaults.object(forKey: websiteAccessKey) != nil
            || defaults.bool(forKey: accessConfirmedKey)
        // Website access implies the extension is enabled.
        let enabled = access
            || defaults.object(forKey: enabledKey) != nil
            || defaults.bool(forKey: enabledConfirmedKey)
        hasWebsiteAccess = access
        isExtensionEnabled = enabled
    }

    func confirmEnabled() {
        defaults.set(true, forKey: enabledConfirmedKey)
        refresh()
    }

    func confirmWebsiteAccess() {
        defaults.set(true, forKey: accessConfirmedKey)
        refresh()
    }
}
