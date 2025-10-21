//
//  Viewport.swift
//  Unagent
//
//  Created by Copilot on 2025/10/21.
//

import Foundation

enum Viewport: String, Codable, CaseIterable {
    case desktop = "Desktop"
    case tablet = "Tablet"
    case mobile = "Mobile"
    case none = ""
    
    var displayName: String {
        return NSLocalizedString("Viewport.\(self.rawValue)", comment: "")
    }
}
