import Foundation
import UIKit

/// In-memory LRU cache for images and data
final class CacheManager {
    static let shared = CacheManager()

    private let imageCache = NSCache<NSString, UIImage>()
    private let dataCache = NSCache<NSString, NSData>()

    private init() {
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        dataCache.countLimit = 200
        dataCache.totalCostLimit = 20 * 1024 * 1024 // 20MB

        // Clear on memory warning
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.clearAll()
        }
    }

    // MARK: - Images
    func image(forKey key: String) -> UIImage? {
        imageCache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * 4)
        imageCache.setObject(image, forKey: key as NSString, cost: cost)
    }

    // MARK: - Data
    func data(forKey key: String) -> Data? {
        dataCache.object(forKey: key as NSString) as? Data
    }

    func setData(_ data: Data, forKey key: String) {
        dataCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }

    // MARK: - Clear
    func clearImages() { imageCache.removeAllObjects() }
    func clearData() { dataCache.removeAllObjects() }
    func clearAll() { clearImages(); clearData() }
}

// MARK: - Async Image Loader
actor ImageLoader {
    static let shared = ImageLoader()

    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    func load(url: URL) async -> UIImage? {
        // Check cache first
        if let cached = CacheManager.shared.image(forKey: url.absoluteString) {
            return cached
        }

        // Deduplicate in-flight requests
        if let existing = inFlight[url] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return nil }
            CacheManager.shared.setImage(image, forKey: url.absoluteString)
            return image
        }

        inFlight[url] = task
        let result = await task.value
        inFlight[url] = nil
        return result
    }
}
