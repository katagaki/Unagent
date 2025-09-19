//
//  SiteSettingRow.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/08/23.
//

import FaviconFinder
import SwiftUI

struct SiteSettingRow: View {

    @State var favicon: UIImage? = nil
    @State var isFirstFaviconFetchCompleted: Bool = false
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let favicon = favicon {
                Image(uiImage: favicon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .fixedSize()
                    .clipShape(RoundedRectangle(cornerRadius: 2.0))
            } else {
                Image(systemName: "globe")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .fixedSize()
                    .task {
                        if !isFirstFaviconFetchCompleted {
                            var url = title
                            if !url.starts(with: "https://") || !url.starts(with: "http://") {
                                url = "https://\(url)"
                            }
                            do {
                                let downloadedFavicon = try await FaviconFinder(
                                    url: URL(string: url)!,
                                    preferredType: .html,
                                    preferences: [
                                        .html: FaviconType.appleTouchIcon.rawValue,
                                        .ico: "favicon.ico",
                                        .webApplicationManifestFile: FaviconType.launcherIcon4x.rawValue
                                    ]
                                ).downloadFavicon()
                                favicon = downloadedFavicon.image
                            } catch {
                                debugPrint("Favicon not found.")
                            }
                            isFirstFaviconFetchCompleted = true
                        }
                    }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .tint(.primary)
        }
    }
}
