import Foundation

struct Preset: Codable, Identifiable {
    var id: UUID
    var name: String
    var imageName: String
    var iconURL: String?
    var category: String?
    var userAgent: String
    var source: String?
    var sources: [String]?
    var viewport: Viewport?
    var emulation: Emulation?
    var isBuiltIn: Bool

    init(id: UUID = UUID(), name: String, imageName: String = "", iconURL: String? = nil,
         category: String? = nil, userAgent: String, source: String? = nil,
         sources: [String]? = nil, viewport: Viewport? = nil, emulation: Emulation? = nil,
         isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.iconURL = iconURL
        self.category = category
        self.userAgent = userAgent
        self.source = source
        self.sources = sources
        self.viewport = viewport
        self.emulation = emulation
        self.isBuiltIn = isBuiltIn
    }

    enum CodingKeys: String, CodingKey {
        case id, name, imageName, iconURL, category, userAgent, source, sources, viewport, emulation, isBuiltIn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.imageName = (try? container.decodeIfPresent(String.self, forKey: .imageName)) ?? ""
        self.iconURL = try container.decodeIfPresent(String.self, forKey: .iconURL)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.userAgent = try container.decode(String.self, forKey: .userAgent)
        self.source = try container.decodeIfPresent(String.self, forKey: .source)
        self.sources = try container.decodeIfPresent([String].self, forKey: .sources)
        self.viewport = try container.decodeIfPresent(Viewport.self, forKey: .viewport)
        self.emulation = try container.decodeIfPresent(Emulation.self, forKey: .emulation)
        self.isBuiltIn = (try? container.decode(Bool.self, forKey: .isBuiltIn)) ?? true
    }

    var allSources: [String] {
        var result: [String] = []
        if let source = source, !source.isEmpty {
            result.append(source)
        }
        if let sources = sources {
            result.append(contentsOf: sources.filter { !$0.isEmpty })
        }
        return result
    }

    var displayName: String {
        userAgent.isEmpty
            ? NSLocalizedString("Presets.Detail.Default", comment: "")
            : name
    }
}
