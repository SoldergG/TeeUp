import Foundation

extension String {
    // MARK: - Validation
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    var isValidUsername: Bool {
        let pattern = #"^[a-zA-Z0-9_]{3,20}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    var isNotEmpty: Bool { !isEmpty }

    // MARK: - Trimming
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var nilIfEmpty: String? { isEmpty ? nil : self }

    // MARK: - Initials
    var initials: String {
        let parts = split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map { String($0).uppercased() }.joined()
    }

    var firstInitial: String {
        String(prefix(1)).uppercased()
    }

    // MARK: - Truncation
    func truncated(to length: Int, trailing: String = "…") -> String {
        count > length ? String(prefix(length)) + trailing : self
    }

    // MARK: - Localized score display
    var scoreLabel: String {
        switch self {
        case "eagle": return "Eagle"
        case "birdie": return "Birdie"
        case "par": return "Par"
        case "bogey": return "Bogey"
        case "double_bogey": return "Double Bogey"
        default: return self.capitalized
        }
    }

    // MARK: - URL encoding
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

// MARK: - Optional String
extension Optional where Wrapped == String {
    var orEmpty: String { self ?? "" }
    var isNilOrEmpty: Bool { self?.isEmpty ?? true }
}
