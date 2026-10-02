import Foundation

enum OpeningHoursCheckDateFormatter {
    private static let inputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()

    static func format(_ rawValue: String?, locale: Locale = .current) -> String? {
        guard let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        guard value.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil,
              let date = inputFormatter.date(from: value),
              inputFormatter.string(from: date) == value else { return value }
        let outputFormatter = DateFormatter()
        outputFormatter.locale = locale
        outputFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .none
        return outputFormatter.string(from: date)
    }
}
