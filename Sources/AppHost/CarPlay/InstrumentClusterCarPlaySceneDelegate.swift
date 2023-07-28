import CarPlay

@available(iOS 15.4, *)
class InstrumentClusterCarPlaySceneDelegate: NSObject,
                                             CPTemplateApplicationInstrumentClusterSceneDelegate,
                                             CPInstrumentClusterControllerDelegate {
    func instrumentClusterControllerDidConnect(_ instrumentClusterWindow: UIWindow) {
        print(#function)
    }
    
    func instrumentClusterControllerDidDisconnectWindow(_ instrumentClusterWindow: UIWindow) {
        print(#function)
    }
    
    func templateApplicationInstrumentClusterScene(_ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene, didConnect instrumentClusterController: CPInstrumentClusterController) {
        instrumentClusterController.delegate = self
        print(#function)
    }
    
    func templateApplicationInstrumentClusterScene(_ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene, didDisconnectInstrumentClusterController instrumentClusterController: CPInstrumentClusterController) {
        print(#function)
    }
}
