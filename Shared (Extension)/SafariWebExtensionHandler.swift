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

    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems[0] as! NSExtensionItem
        let message = item.userInfo?[SFExtensionMessageKey]
        let response = NSExtensionItem()
        response.userInfo = [ SFExtensionMessageKey: [ "Response to": message ] ]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

}
