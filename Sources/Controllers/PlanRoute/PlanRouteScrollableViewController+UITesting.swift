#if DEBUG
import UIKit

extension PlanRouteScrollableViewController {
    func setupUITestStateIfNeeded(in toolbar: UIView, controllerState: @escaping () -> (calculating: Bool, editing: Bool)?) {
        guard UITestState.isPlanRouteHistoryEnabled else { return }
        let stateView = PlanRouteUITestStateView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        stateView.isAccessibilityElement = true
        stateView.accessibilityLabel = "Plan Route test state"
        stateView.isUserInteractionEnabled = false
        stateView.accessibilityIdentifier = UITestAccessibilityIdentifier.PlanRoute.state
        stateView.translatesAutoresizingMaskIntoConstraints = false
        stateView.snapshot = {
            guard let controllerState = controllerState(),
                  var state = OAMeasurementToolLayer.currentRouteStateForUITesting() else { return nil }
            state["calculating"] = controllerState.calculating
            state["editing"] = controllerState.editing
            return state
        }
        toolbar.addSubview(stateView)
        NSLayoutConstraint.activate([
            stateView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            stateView.topAnchor.constraint(equalTo: toolbar.safeAreaLayoutGuide.topAnchor),
            stateView.widthAnchor.constraint(equalToConstant: 1),
            stateView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}
#endif
