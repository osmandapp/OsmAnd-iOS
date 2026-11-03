#if DEBUG
import UIKit

final class PlanRouteUITestStateView: UIView {
    var snapshot: (() -> [String: Any]?)?

    override var accessibilityValue: String? {
        get {
            guard let snapshot = snapshot?(),
                  let data = try? JSONSerialization.data(withJSONObject: snapshot, options: .sortedKeys) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set { }
    }
}
#endif
