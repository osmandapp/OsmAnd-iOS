import CarPlay

final class CarPlaySceneLifecycleCoordinator {
    static let shared = CarPlaySceneLifecycleCoordinator()

    private var shouldCenterOnMyLocation = true

    private init() {}

    func sceneDidDisconnect(_ scene: UIScene) {
        let hasConnectedCarPlayScene = UIApplication.shared.connectedScenes.contains {
            $0 !== scene && $0.activationState != .unattached &&
                ($0 is CPTemplateApplicationScene || $0 is CPTemplateApplicationDashboardScene)
        }
        guard !hasConnectedCarPlayScene else { return }
        shouldCenterOnMyLocation = true
    }

    func centerOnMyLocationIfNeeded() {
        guard shouldCenterOnMyLocation,
              let app = OsmAndApp.swiftInstance(),
              let locationServices = app.locationServices else { return }
        shouldCenterOnMyLocation = false

        guard !locationServices.denied else { return }
        app.mapMode = .positionTrack
        if locationServices.status == .suspended {
            locationServices.resume()
        }
    }
}
