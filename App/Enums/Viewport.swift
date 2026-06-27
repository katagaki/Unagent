import Foundation

enum Viewport: String, Codable, CaseIterable {
    case desktop = "Desktop"
    case tablet = "Tablet"
    case mobile = "Mobile"
    case none = ""

    var displayName: String {
        return NSLocalizedString("Viewport.\(self.rawValue)", comment: "")
    }

    var iconName: String? {
        switch self {
        case .desktop: "desktopcomputer"
        case .tablet: "ipad"
        case .mobile: "iphone"
        case .none: nil
        }
    }
}
