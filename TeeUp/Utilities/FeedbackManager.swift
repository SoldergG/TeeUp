import StoreKit
import UIKit

/// Handles app review requests and user feedback
enum FeedbackManager {
    private static let roundsBeforeReview = 5
    private static let reviewRequestKey = "lastReviewRequestDate"
    private static let roundsCompletedKey = "roundsCompletedCount"

    /// Call after completing a round
    static func roundCompleted() {
        let count = UserDefaults.standard.integer(forKey: roundsCompletedKey) + 1
        UserDefaults.standard.set(count, forKey: roundsCompletedKey)

        if shouldRequestReview(roundsCompleted: count) {
            requestReview()
        }
    }

    private static func shouldRequestReview(roundsCompleted: Int) -> Bool {
        guard roundsCompleted >= roundsBeforeReview,
              roundsCompleted % roundsBeforeReview == 0 else { return false }

        // Max once per 60 days
        if let last = UserDefaults.standard.object(forKey: reviewRequestKey) as? Date {
            return Date.now.timeIntervalSince(last) > 60 * 86400
        }
        return true
    }

    private static func requestReview() {
        UserDefaults.standard.set(Date.now, forKey: reviewRequestKey)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    /// Open mail compose or mailto link
    static func sendSupportEmail() {
        let subject = "TeeUp Suporte - v\(AppInfo.version)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = "\n\n---\nDispositivo: \(AppInfo.deviceModel)\niOS: \(AppInfo.osVersion)\nApp: \(AppInfo.versionDisplay)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(AppInfo.supportEmail)?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }
}
