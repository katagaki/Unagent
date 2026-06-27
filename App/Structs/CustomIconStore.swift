import UIKit

enum CustomIconStore {

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("CustomIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func isCustomIcon(_ imageName: String) -> Bool {
        imageName.hasSuffix(".png")
    }

    static func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    static func save(_ image: UIImage, maxDimension: CGFloat = 256.0) -> String? {
        let scaled = image.scaledToFit(maxDimension: maxDimension)
        guard let data = scaled.pngData() else { return nil }
        let filename = UUID().uuidString + ".png"
        do {
            try data.write(to: url(for: filename))
            return filename
        } catch {
            return nil
        }
    }
}

extension UIImage {
    func scaledToFit(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
