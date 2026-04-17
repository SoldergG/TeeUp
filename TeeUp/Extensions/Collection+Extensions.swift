import Foundation

extension Collection {
    /// Safe subscript — returns nil for out-of-bounds index
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    var isNotEmpty: Bool { !isEmpty }
}

extension Array {
    /// Splits array into chunks of given size
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element: Identifiable {
    /// Replace or append an element by ID
    mutating func upsert(_ element: Element) {
        if let idx = firstIndex(where: { $0.id == element.id }) {
            self[idx] = element
        } else {
            append(element)
        }
    }

    /// Remove element by ID
    mutating func remove(id: Element.ID) {
        removeAll { $0.id == id }
    }
}

extension Sequence where Element: Numeric {
    var sum: Element { reduce(0, +) }
}

extension Collection where Element: BinaryFloatingPoint {
    var average: Double {
        guard isNotEmpty else { return 0 }
        return Double(reduce(0, +)) / Double(count)
    }
}

extension Collection where Element: BinaryInteger {
    var average: Double {
        guard isNotEmpty else { return 0 }
        return Double(reduce(0, +)) / Double(count)
    }
}
