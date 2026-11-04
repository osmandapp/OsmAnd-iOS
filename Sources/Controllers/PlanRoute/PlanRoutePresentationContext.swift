struct PlanRoutePresentationContext {

    static let standard = PlanRoutePresentationContext(followTrackMode: false,
                                                        showSnapWarning: false,
                                                        appliesApproximationToNavigation: false)

    let followTrackMode: Bool
    let showSnapWarning: Bool
    let appliesApproximationToNavigation: Bool

    static func followTrack(attachToRoads: Bool) -> PlanRoutePresentationContext {
        PlanRoutePresentationContext(followTrackMode: true,
                                     showSnapWarning: attachToRoads,
                                     appliesApproximationToNavigation: attachToRoads)
    }
}
