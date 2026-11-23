import CarPlay

final class CarPlaySceneLifecycleCoordinator {
    static let shared = CarPlaySceneLifecycleCoordinator()

    private var connectedScenes: Set<ObjectIdentifier> = []
    private var shouldCenterOnMyLocation = true

    private init() {}

    func sceneDidConnect(_ scene: UIScene) {
        if connectedScenes.isEmpty {
            shouldCenterOnMyLocation = true
        }
        connectedScenes.insert(ObjectIdentifier(scene))
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        connectedScenes.remove(ObjectIdentifier(scene))
    }

    func centerOnMyLocationIfNeeded(showRouteOverview: (() -> Void)? = nil) {
        guard shouldCenterOnMyLocation,
              let app = OsmAndApp.swiftInstance(),
              let locationServices = app.locationServices else { return }
        shouldCenterOnMyLocation = false

        guard !locationServices.denied else { return }
        let routingHelper = OARoutingHelper.sharedInstance()
        if routingHelper.isRouteCalculated() && !routingHelper.isFollowingMode() {
            showRouteOverview?()
        } else {
            app.mapMode = .positionTrack
        }
        if locationServices.status == .suspended {
            locationServices.resume()
        }
    }
}
