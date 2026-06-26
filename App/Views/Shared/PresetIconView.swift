//
//  PresetIconView.swift
//  Unagent
//
//  Renders a preset's icon. Prefers a remotely fetched store icon
//  (iconURL, cached in memory for the session), falling back to a
//  bundled asset, then an SF Symbol, then nothing — keeping row
//  alignment via a reserved frame.
//

import SwiftUI

struct PresetIconView: View {
    let preset: Preset
    var size: CGFloat = 24.0

    @State private var loadedImage: UIImage?

    /// App Store, Play Store, and Apple (apple-touch) icons are square artwork
    /// cropped to a rounded rect (app-tile look); other logos/favicons stay flat.
    private var shouldRound: Bool {
        guard let iconURL = preset.iconURL else { return false }
        return iconURL.contains("mzstatic.com")
            || iconURL.contains("play-lh.googleusercontent.com")
            || iconURL.contains("apple.com")
    }

    /// The image source: a remote store icon, or a saved custom-icon file.
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
