import Foundation

/// Lightweight local analytics for tracking user behavior patterns
/// (no external dependencies — data stays on-device)
enum AnalyticsTracker {
    private static let key = "analytics_events"
    private static let maxEvents = 500

    struct Event: Codable {
        let name: String
        let timestamp: Date
        let properties: [String: String]
    }

    // MARK: - Track events
    static func track(_ name: String, properties: [String: String] = [:]) {
        var events = loadEvents()
        events.append(Event(name: name, timestamp: .now, properties: properties))

        // Keep only last N events
        if events.count > maxEvents {
            events = Array(events.suffix(maxEvents))
        }

        save(events)
    }

    // MARK: - Common events
    static func roundStarted(course: String) {
        track("round_started", properties: ["course": course])
    }

    static func roundCompleted(course: String, score: Int) {
        track("round_completed", properties: ["course": course, "score": "\(score)"])
    }

    static func courseViewed(name: String) {
        track("course_viewed", properties: ["name": name])
    }

    static func friendAdded() {
        track("friend_added")
    }

    static func gameSessionCreated() {
        track("game_session_created")
    }

    static func searchPerformed(query: String) {
        track("search", properties: ["query": query])
    }

    // MARK: - Aggregation
    static func roundsThisMonth() -> Int {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
        return loadEvents().filter { $0.name == "round_completed" && $0.timestamp >= start }.count
    }

    static func mostPlayedCourse() -> String? {
        let courses = loadEvents()
            .filter { $0.name == "round_completed" }
            .compactMap { $0.properties["course"] }
        let counts = Dictionary(courses.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Storage
    private static func loadEvents() -> [Event] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Event].self, from: data)) ?? []
    }

    private static func save(_ events: [Event]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
