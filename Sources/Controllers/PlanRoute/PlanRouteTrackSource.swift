import Foundation

struct PlanRouteTrackSource {

    let editableFilePath: String?
    let sourceFilePath: String?

    var waypointEditingFilePath: String? {
        resolvedFilePath
    }

    private var resolvedFilePath: String? {
        editableFilePath ?? sourceFilePath
    }

    init(gpxFilePath: String, sourceFilePath: String?) {
        editableFilePath = gpxFilePath.isEmpty ? nil : gpxFilePath
        self.sourceFilePath = sourceFilePath?.isEmpty == false ? sourceFilePath : editableFilePath
    }

    func savingFolder(relativeTo gpxRootPath: String?) -> String? {
        guard var path = resolvedFilePath else { return nil }
        if (path as NSString).isAbsolutePath, let gpxRootPath, path.hasPrefix(gpxRootPath) {
            path = String(path.dropFirst(gpxRootPath.count))
        }
        let folder = (path as NSString).deletingLastPathComponent.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return folder.isEmpty ? nil : folder
    }
}
