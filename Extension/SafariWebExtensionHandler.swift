//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by シンジャスティン on 2023/04/23.
//

import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    let defaults: UserDefaults = UserDefaults(
        suiteName: "group.\(Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".Extension", with: ""))"
    )!
    // WARNING: This will break if the extension bundle ID does not follow the format
    //       <bundleID>.Extension

    func beginRequest(with context: NSExtensionContext) {
        let response = NSExtensionItem()
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
                var responseContent: [String:String] = [:]
                if let currentUserAgent = defaults.string(forKey: "UserAgent") {
                    responseContent.updateValue(currentUserAgent, forKey: "userAgent")
                }
                if let siteSettings = defaults.string(forKey: "SiteSettings") {
                    responseContent.updateValue(siteSettings.replacingOccurrences(of: "\\", with: ""), forKey: "siteSettings")
                }
                response.userInfo = ["message": responseContent]

            case "hasExtensionUpdated":
                debugPrint("Extension just told native app it was updated")
                defaults.set(false, forKey: "ShouldExtensionUpdate")

            case "forceExtensionReset":
                debugPrint("Extension was just told to reset all rules")
                defaults.removeObject(forKey: "UserAgent")
                defaults.removeObject(forKey: "SiteSettings")

            default: break
            }
        }
        debugPrint("Extension is going to be told:\n\(response)")
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

}
