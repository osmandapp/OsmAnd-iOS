import Foundation

enum CheckDateFormatter {
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
        guard let value = rawValue, !value.isEmpty else { return nil }
        guard value.range(of: "\\A[ \\t]*\\p{Nd}+-[ \\t]*\\p{Nd}+-[ \\t]*\\p{Nd}+\\z", options: .regularExpression) != nil else { return value }
        var parsedValue: AnyObject?
        var range = NSRange(location: 0, length: (value as NSString).length)
        do {
            try inputFormatter.getObjectValue(&parsedValue, for: value, range: &range)
        } catch {
            return value
        }
        guard range.length == (value as NSString).length, let date = parsedValue as? Date else { return value }
        let outputFormatter = DateFormatter()
        outputFormatter.locale = locale
        outputFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .none
        return outputFormatter.string(from: date)
    }
}
