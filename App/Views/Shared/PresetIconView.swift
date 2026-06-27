import SwiftUI

struct PresetIconView: View {
    let preset: Preset
    var size: CGFloat = 24.0

    @State private var loadedImage: UIImage?

    private var shouldRound: Bool {
        guard let iconURL = preset.iconURL else { return false }
        return iconURL.contains("mzstatic.com")
            || iconURL.contains("play-lh.googleusercontent.com")
            || iconURL.contains("apple.com")
    }

    private var sourceURL: URL? {
        if let iconURL = preset.iconURL, !iconURL.isEmpty, let url = URL(string: iconURL) {
            return url
        }
        if CustomIconStore.isCustomIcon(preset.imageName) {
            return CustomIconStore.url(for: preset.imageName)
        }
        return nil
    }

    var body: some View {
        Group {
            if preset.userAgent.isEmpty {
                // Default ("Don't Change") — circle-slash glyph.
                Image(systemName: "circle.slash")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            } else if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: shouldRound ? size * 0.225 : 0.0,
                            style: .continuous
                        )
                    )
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .task(id: sourceURL) {
            loadedImage = nil
            guard let url = sourceURL else { return }
            if let cached = PresetIconCache.shared.cached(url) {
                loadedImage = cached
                return
            }
            loadedImage = await PresetIconCache.shared.image(for: url)
        }
    }

    @ViewBuilder
    private var fallbackIcon: some View {
        if UIImage(named: preset.imageName) != nil {
            Image(preset.imageName)
                .resizable()
                .scaledToFit()
        } else if !preset.imageName.isEmpty {
            Image(systemName: preset.imageName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        } else {
            Color.clear
        }
    }
}
