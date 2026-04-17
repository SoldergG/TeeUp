import Foundation

extension Date {
    // MARK: - Cached Formatters (performance)
    private static let relativeFmt: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "pt_PT")
        f.unitsStyle = .full
        return f
    }()

    private static let shortDateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_PT")
        f.dateStyle = .short
        return f
    }()

    private static let mediumDateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_PT")
        f.dateStyle = .medium
        return f
    }()

    private static let dayMonthFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_PT")
        f.dateFormat = "d MMM"
        return f
    }()

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let fullFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_PT")
        f.dateFormat = "EEEE, d 'de' MMMM 'de' yyyy"
        return f
    }()

    private static let iso8601Fmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Formatting
    var relativeString: String {
        Self.relativeFmt.localizedString(for: self, relativeTo: .now)
    }

    var shortDate: String { Self.shortDateFmt.string(from: self) }
    var mediumDate: String { Self.mediumDateFmt.string(from: self) }
    var dayMonth: String { Self.dayMonthFmt.string(from: self) }
    var timeString: String { Self.timeFmt.string(from: self) }
    var fullDate: String { Self.fullFmt.string(from: self) }
    var iso8601: String { Self.iso8601Fmt.string(from: self) }

    // MARK: - Comparisons
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
    var isThisWeek: Bool { Calendar.current.isDate(self, equalTo: .now, toGranularity: .weekOfYear) }
    var isThisMonth: Bool { Calendar.current.isDate(self, equalTo: .now, toGranularity: .month) }
    var isThisYear: Bool { Calendar.current.isDate(self, equalTo: .now, toGranularity: .year) }
    var isPast: Bool { self < .now }
    var isFuture: Bool { self > .now }

    // MARK: - Components
    var dayOfWeekPT: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_PT")
        f.dateFormat = "EEEE"
        return f.string(from: self).capitalized
    }

    var daysFromNow: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: self)).day ?? 0
    }

    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    // MARK: - Arithmetic
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    // MARK: - Smart display
    var smartDisplay: String {
        if isToday { return "Hoje, \(timeString)" }
        if isYesterday { return "Ontem, \(timeString)" }
        if isThisWeek { return "\(dayOfWeekPT), \(timeString)" }
        if isThisYear { return dayMonth }
        return shortDate
    }
}
