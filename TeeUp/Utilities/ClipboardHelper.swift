import UIKit

enum ClipboardHelper {
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }

    static var hasString: Bool {
        UIPasteboard.general.hasStrings
    }

    static var string: String? {
        UIPasteboard.general.string
    }

    /// Copy score summary to clipboard
    static func copyScoreSummary(course: String, score: Int, toPar: Int) {
        let parStr = toPar > 0 ? "+\(toPar)" : toPar == 0 ? "E" : "\(toPar)"
        copy("\(course): \(score) (\(parStr))")
    }
}
