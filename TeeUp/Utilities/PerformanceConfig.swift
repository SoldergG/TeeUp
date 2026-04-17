import Foundation
import SwiftUI

// MARK: - 1. Prewarmed URLSession with optimized config
extension URLSession {
    /// Optimized session for API calls with connection pooling and caching
    static let golf: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 4
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,   // 10MB memory
            diskCapacity: 50 * 1024 * 1024,      // 50MB disk
            directory: nil
        )
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()
}

// MARK: - 2. Equatable wrappers for reducing view redraws
struct EquatableWrapper<Value>: Equatable {
    let value: Value
    let isEqual: (Value, Value) -> Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isEqual(lhs.value, rhs.value)
    }
}

// MARK: - 3. Task cancellation helper
extension View {
    /// Runs a task that auto-cancels when view disappears
    func cancellableTask(id: some Hashable, _ action: @Sendable @escaping () async -> Void) -> some View {
        task(id: id) { await action() }
    }
}

// MARK: - 4. Lazy NavigationLink (defers destination creation)
struct LazyNavigationLink<Label: View, Destination: View>: View {
    let destination: () -> Destination
    let label: () -> Label

    @State private var isActive = false

    var body: some View {
        Button { isActive = true } label: { label() }
            .navigationDestination(isPresented: $isActive) { destination() }
    }
}

// MARK: - 5. Batch processing for SwiftData
@MainActor
enum BatchProcessor {
    /// Process items in batches to avoid blocking the main thread
    static func process<T>(
        items: [T],
        batchSize: Int = 50,
        action: (T) -> Void
    ) async {
        for batch in items.chunked(into: batchSize) {
            for item in batch {
                action(item)
            }
            // Yield to main thread between batches
            await Task.yield()
        }
    }
}

// MARK: - 6. Compiled predicates for frequently used queries
enum PrecompiledPredicates {
    static let completedRounds = #Predicate<Round> { $0.isCompleted }
    static let inProgressRounds = #Predicate<Round> { !$0.isCompleted }
}

// MARK: - 7. Memory-efficient image downsampling
import UIKit

enum ImageProcessor {
    static func downsample(data: Data, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
}

// MARK: - 8. App startup optimizer
enum StartupOptimizer {
    @MainActor
    static func performDeferredSetup() {
        Task(priority: .background) {
            // Prewarm formatters
            _ = Date().relativeString
            _ = Date().shortDate

            // Prewarm network monitor
            _ = NetworkMonitor.shared.isConnected

            // Configure audio session
            SoundManager.configure()

            // Increment launch count
            UserDefaults.standard.appLaunchCount += 1
        }
    }
}

// MARK: - 9. Efficient string hashing for cache keys
extension String {
    var stableHash: Int {
        var hasher = Hasher()
        hasher.combine(self)
        return hasher.finalize()
    }
}

// MARK: - 10. Reduce animation complexity on low-power
extension View {
    @ViewBuilder
    func reduceMotionSafe<V: Equatable>(value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self.animation(nil, value: value)
        } else {
            self.animation(.spring(duration: 0.3), value: value)
        }
    }
}
