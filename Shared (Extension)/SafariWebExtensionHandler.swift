//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by 堅書 on 2023/04/23.
//

import SafariServices
import os.log

let SFExtensionMessageKey = "message"

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    let defaults: UserDefaults = UserDefaults(suiteName: "group.com.tsubuzaki.BingBong")!

    func beginRequest(with context: NSExtensionContext) {
        let response = NSExtensionItem()
        if let currentUserAgent = defaults.string(forKey: "UserAgent") {
            response.userInfo = [
                SFExtensionMessageKey: ["userAgent": currentUserAgent]
            ]
        }
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

}
