struct PlanRouteTrackSource {

    let editableFilePath: String?
    let sourceFilePath: String?

    var waypointEditingFilePath: String? {
        editableFilePath ?? sourceFilePath
    }

    init(gpxFilePath: String, sourceFilePath: String?) {
        editableFilePath = gpxFilePath.isEmpty ? nil : gpxFilePath
        self.sourceFilePath = sourceFilePath?.isEmpty == false ? sourceFilePath : editableFilePath
    }
}
