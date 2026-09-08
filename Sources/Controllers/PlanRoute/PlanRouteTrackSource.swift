struct PlanRouteTrackSource {

    let editableFilePath: String?
    let sourceFilePath: String?

    init(gpxFilePath: String, sourceFilePath: String?) {
        editableFilePath = gpxFilePath.isEmpty ? nil : gpxFilePath
        self.sourceFilePath = sourceFilePath?.isEmpty == false ? sourceFilePath : editableFilePath
    }
}
