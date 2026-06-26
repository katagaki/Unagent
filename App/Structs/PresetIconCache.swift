//
//  PresetIconCache.swift
//  Unagent
//
//  In-memory cache for remotely fetched preset icons. Entries persist
//  for the lifetime of the app process (cleared when the app closes),
//  so list scrolling and re-entering views never re-download an icon.
//

import SwiftUI

@MainActor
final class PresetIconCache {
    static let shared = PresetIconCache()

    private var cache: [URL: UIImage] = [:]
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    /// Synchronously returns a cached image if present (no fetch).
    func cached(_ url: URL) -> UIImage? { cache[url] }

    /// Returns the image for a URL, fetching and caching it if needed.
    /// Concurrent requests for the same URL share a single download.
    func image(for url: URL) async -> UIImage? {
        if let image = cache[url] { return image }
        if let task = inFlight[url] { return await task.value }

        let task = Task<UIImage?, Never> {
            if url.isFileURL {
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else { return nil }
                return image
            }
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let image = UIImage(data: data) else {
                return nil
            }
            return image
        }
        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        if let image { cache[url] = image }
        return image
    }
}
