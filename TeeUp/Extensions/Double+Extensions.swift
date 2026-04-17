import Foundation

extension Double {
    // MARK: - Distance Formatting
    var kmFormatted: String {
        if self < 1 {
            return "\(Int(self * 1000)) m"
        }
        return String(format: "%.1f km", self)
    }

    var milesFormatted: String {
        String(format: "%.1f mi", self * 0.621371)
    }

    var yardsFormatted: String {
        "\(Int(self * 1093.61)) yd"
    }

    var metersFormatted: String {
        "\(Int(self)) m"
    }

    // MARK: - Score Formatting
    var handicapDisplay: String {
        if self == self.rounded() {
            return String(format: "%.0f", self)
        }
        return String(format: "%.1f", self)
    }

    var scoreToParDisplay: String {
        if self > 0 { return "+\(Int(self))" }
        if self == 0 { return "E" }
        return "\(Int(self))"
    }

    var percentageDisplay: String {
        String(format: "%.0f%%", self * 100)
    }

    // MARK: - Rounding
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    // MARK: - Clamping
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    // MARK: - Currency
    var euroFormatted: String {
        String(format: "%.2f €", self)
    }
}

extension Int {
    var scoreToParDisplay: String {
        if self > 0 { return "+\(self)" }
        if self == 0 { return "E" }
        return "\(self)"
    }

    var ordinalPT: String {
        "\(self)º"
    }

    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
