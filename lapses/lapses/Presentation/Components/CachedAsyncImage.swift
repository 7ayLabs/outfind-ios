import SwiftUI
import os

// MARK: - Image Cache

/// Thread-safe image cache using NSCache
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let lock = OSAllocatedUnfairLock()

    private init() {
        // Limit cache to ~50MB
        cache.totalCostLimit = 50 * 1024 * 1024
        cache.countLimit = 100
    }

    func image(for url: URL) -> UIImage? {
        lock.withLock {
            cache.object(forKey: url.absoluteString as NSString)
        }
    }

    func setImage(_ image: UIImage, for url: URL) {
        lock.withLock {
            let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
            cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
        }
    }

    func removeImage(for url: URL) {
        lock.withLock {
            cache.removeObject(forKey: url.absoluteString as NSString)
        }
    }

    func clearCache() {
        lock.withLock {
            cache.removeAllObjects()
        }
    }
}

// MARK: - Cached Async Image

/// Memory-efficient async image loader with caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let scale: CGFloat
    let transaction: Transaction
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onChange(of: url) { _, newURL in
            loadedImage = nil
            if newURL != nil {
                loadImage()
            }
        }
    }

    private func loadImage() {
        guard let url, !isLoading else { return }

        // Check cache first
        if let cached = ImageCache.shared.image(for: url) {
            withTransaction(transaction) {
                loadedImage = cached
            }
            return
        }

        // Load from network
        isLoading = true

        Task.detached(priority: .userInitiated) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    // Downscale if too large (optimize memory)
                    let optimized = image.optimizedForDisplay(maxDimension: 1200)
                    ImageCache.shared.setImage(optimized, for: url)

                    await MainActor.run {
                        withTransaction(transaction) {
                            loadedImage = optimized
                            isLoading = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, scale: scale, content: content) {
            ProgressView()
        }
    }
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, scale: CGFloat = 1.0) {
        self.init(url: url, scale: scale) { image in
            image
        } placeholder: {
            ProgressView()
        }
    }
}

// MARK: - UIImage Optimization Extension

private extension UIImage {
    /// Downscale image to reduce memory footprint
    func optimizedForDisplay(maxDimension: CGFloat) -> UIImage {
        let currentMax = max(size.width, size.height)
        guard currentMax > maxDimension else { return self }

        let scaleFactor = maxDimension / currentMax
        let newSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CachedAsyncImage(url: URL(string: "https://picsum.photos/200")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        CachedAsyncImage(url: URL(string: "https://i.pravatar.cc/100")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle().fill(Color.gray.opacity(0.3))
        }
        .frame(width: 60, height: 60)
        .clipShape(Circle())
    }
}
