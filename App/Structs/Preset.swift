//
//  Preset.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import Foundation

struct Preset: Codable, Identifiable {
    var id: UUID
    var name: String
    var imageName: String
    var userAgent: String
    var source: String?
    var sources: [String]?
    var viewport: Viewport?
    var isBuiltIn: Bool

    init(id: UUID = UUID(), name: String, imageName: String, userAgent: String,
         source: String? = nil, sources: [String]? = nil,
         viewport: Viewport? = nil, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.userAgent = userAgent
        self.source = source
        self.sources = sources
        self.viewport = viewport
        self.isBuiltIn = isBuiltIn
    }

    enum CodingKeys: String, CodingKey {
        case id, name, imageName, userAgent, source, sources, viewport, isBuiltIn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.imageName = try container.decode(String.self, forKey: .imageName)
        self.userAgent = try container.decode(String.self, forKey: .userAgent)
        self.source = try container.decodeIfPresent(String.self, forKey: .source)
        self.sources = try container.decodeIfPresent([String].self, forKey: .sources)
        self.viewport = try container.decodeIfPresent(Viewport.self, forKey: .viewport)
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
}
