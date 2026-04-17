import UIKit
import SwiftUI

/// Share round results, course info, etc.
enum ShareManager {
    static func shareRoundSummary(
        courseName: String,
        date: Date,
        score: Int,
        toPar: Int,
        handicap: Double?
    ) {
        let parStr = toPar > 0 ? "+\(toPar)" : toPar == 0 ? "E" : "\(toPar)"
        var text = "Joguei \(score) (\(parStr)) em \(courseName) no dia \(date.dayMonth)."
        if let hcp = handicap {
            text += " HCP: \(String(format: "%.1f", hcp))"
        }
        text += "\n\nRegistado com TeeUp"
        share(items: [text])
    }

    static func shareCourse(name: String, rating: Double, distance: String) {
        let text = "\(name) - ★ \(String(format: "%.1f", rating)) - \(distance)\n\nDescoberto com TeeUp"
        share(items: [text])
    }

    static func shareGameInvite(courseName: String, date: Date) {
        let text = "Vamos jogar golfe! 🏌️\n\n📍 \(courseName)\n📅 \(date.fullDate)\n⏰ \(date.timeString)\n\nJunta-te a mim no TeeUp!"
        share(items: [text])
    }

    private static func share(items: [Any]) {
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
              let root = scene.windows.first?.rootViewController else { return }
        // iPad popover support
        if let popover = ac.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        root.present(ac, animated: true)
    }
}
