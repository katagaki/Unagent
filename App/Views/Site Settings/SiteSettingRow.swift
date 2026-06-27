import FaviconFinder
import SwiftUI

struct SiteSettingRow: View {

    @State var favicon: UIImage?
    @State var isFirstFaviconFetchCompleted: Bool = false
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // A fixed icon box keeps rows aligned whether the favicon loaded or
            // the globe fallback is shown.
            Group {
                if let favicon = favicon {
                    Image(uiImage: favicon)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 4.0))
                } else {
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 20, height: 20)

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
        // Pin to the leading edge — otherwise the row sizes to its content and a
        // short row gets centred, pushing the icon off the leading edge.
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await fetchFaviconIfNeeded() }
    }

    private func fetchFaviconIfNeeded() async {
        guard !isFirstFaviconFetchCompleted else { return }
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
