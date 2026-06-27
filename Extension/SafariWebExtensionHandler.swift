import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    let defaults: UserDefaults = UserDefaults(
        suiteName: "group.\(Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".Extension", with: ""))"
    )!
    // WARNING: This will break if the extension bundle ID does not follow the format
    //       <bundleID>.Extension

    // Activation heartbeat keys (read by the main app's onboarding to confirm setup).
    private static let enabledLastSeenKey = "ExtensionEnabledLastSeen"
    private static let websiteAccessLastSeenKey = "ExtensionWebsiteAccessLastSeen"

    func beginRequest(with context: NSExtensionContext) {
        let response = NSExtensionItem()

        // This handler can only run when the extension is enabled and executing,
        // so every invocation is proof the extension is turned on.
        defaults.set(Date().timeIntervalSince1970, forKey: Self.enabledLastSeenKey)
        /*
         Contents of context.inputItems:
         [<NSExtensionItem> - userInfo: {
             NSExtensionItemAttachmentsKey =     (
             );
             message =     {
                 function = xxxxx;
             };
         }]
         */
        if let inputItems = context.inputItems.first as? NSExtensionItem,
           let userInfo = inputItems.userInfo as? [String: Any],
           let message = userInfo[SFExtensionMessageKey] as? [String: String],
           let functionName = message["function"] {

            switch functionName {
            case "shouldExtensionUpdate":
                debugPrint("Extension just asked native app whether it should update")
                response.userInfo = [
                    "message": ["shouldExtensionUpdate": defaults.bool(forKey: "ShouldExtensionUpdate")]
                ]

            case "getSettings":
                debugPrint("Extension just asked native app for site settings")
                var responseContent: [String: String] = [:]
                if let currentUserAgent = defaults.string(forKey: "UserAgent") {
                    responseContent.updateValue(currentUserAgent, forKey: "userAgent")
                }
                if let globalViewport = defaults.string(forKey: "GlobalViewport") {
                    responseContent.updateValue(globalViewport, forKey: "globalViewport")
                }
                if let siteSettings = defaults.string(forKey: "SiteSettings") {
                    responseContent.updateValue(siteSettings.replacingOccurrences(of: "\\", with: ""), forKey: "siteSettings")
                }
                responseContent.updateValue(
                    defaults.bool(forKey: "AutoRefreshEnabled") ? "true" : "false",
                    forKey: "autoRefreshEnabled"
                )
                response.userInfo = ["message": responseContent]

            case "getPresets":
                debugPrint("Extension just asked native app for presets")
                var responseContent: [String: String] = [:]
                if let presets = defaults.string(forKey: "ExtensionPresets") {
                    responseContent.updateValue(presets, forKey: "presets")
                }
                response.userInfo = ["message": responseContent]

            case "saveSettings":
                debugPrint("Extension just asked native app to save settings")
                // Write-back from the popup so the app's UI (which reads these
                // keys via @AppStorage) reflects changes made in the extension.
                // The extension already applied its own rules, so we do NOT set
                // ShouldExtensionUpdate (that would trigger a redundant re-pull).
                if let userAgent = message["userAgent"] {
                    defaults.set(userAgent, forKey: "UserAgent")
                }
                if let globalViewport = message["globalViewport"] {
                    defaults.set(globalViewport, forKey: "GlobalViewport")
                }
                if let siteSettings = message["siteSettings"] {
                    defaults.set(siteSettings, forKey: "SiteSettings")
                }
                defaults.synchronize()

            case "reportEnabled":
                // Sent from the background script on Safari launch / extension
                // enable. The enabled timestamp is already written at the top of
                // beginRequest; this case is here for clarity and logging.
                debugPrint("Extension reported it is enabled")

            case "reportActivation":
                // Sent from the background script, which only runs when the content
                // script fires on a page — i.e. the extension is enabled AND has been
                // granted website access. The app uses this to confirm setup is done.
                debugPrint("Extension reported it is active on a page")
                defaults.set(Date().timeIntervalSince1970, forKey: Self.websiteAccessLastSeenKey)

            case "hasExtensionUpdated":
                debugPrint("Extension just told native app it was updated")
                defaults.set(false, forKey: "ShouldExtensionUpdate")

            case "forceExtensionReset":
                debugPrint("Extension was just told to reset all rules")
                defaults.removeObject(forKey: "UserAgent")
                defaults.removeObject(forKey: "GlobalViewport")
                defaults.removeObject(forKey: "SiteSettings")

            default: break
            }
        }
        defaults.synchronize()
        debugPrint("Extension is going to be told:\n\(response)")
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

}
