//
//  Model3dHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 21/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class Model3dHelper: NSObject {
    
    typealias callbackWithModel3d = (_ model: OAModel3dWrapper?) -> Void
    
    static let shared = Model3dHelper()
    
    private let app: OsmAndAppProtocol
    private let settings: OAAppSettings
    
    private var modelsCache = [String: OAModel3dWrapper]()
    private var modelsInProgress = Set<String>()
    private var failedModels = Set<String>()
    
    private override init() {
        app = OsmAndApp.swiftInstance()
        settings = OAAppSettings.sharedManager()
    }
    
    func getModel(modelName: String, callbackOnLoad: callbackWithModel3d?) -> OAModel3dWrapper? {
        if !modelName.hasPrefix(MODEL_NAME_PREFIX) {
            guard let callbackOnLoad else { return nil }
                callbackOnLoad(nil)
        }
        
        let pureModelName = modelName.replacingOccurrences(of: MODEL_NAME_PREFIX, with: "")
        let model3D = modelsCache[pureModelName]
        if model3D == nil {
            loadModel(modelName: pureModelName, callback: callbackOnLoad)
        }
        
        return model3D
    }
    
    private func loadModel(modelName: String, callback: callbackWithModel3d?) {
        if !app.initialized {
            
            // TODO: implement
            
        } else {
            loadModelImpl(modelName: modelName, callback: callback)
        }
    }
    
    private func loadModelImpl(modelName: String, callback: callbackWithModel3d?) {
        if modelsCache[modelName] != nil || modelsInProgress.contains(modelName) || failedModels.contains(modelName) {
            return
        }
        
        let modelDirPath = app.documentsPath.appendingPathComponent(MODEL_3D_DIR).appendingPathComponent(modelName)
        if !Model3dHelper.isModelExist(dir: modelDirPath) {
            return
        }
        
        modelsInProgress.insert(modelName)
        
        let task = OALoad3dModelTask(modelName) { [weak self] model in
            if model == nil {
                self?.failedModels.insert(modelName)
            } else {
                self?.modelsCache[modelName] = model
            }
            self?.modelsInProgress.remove(modelName)
            if let callback {
                callback(model)
            }
            return true
        }
        task?.execute()
    }
    
    static func listModels() -> [String] {
        var modelsDirNames = [String]()
        do {
            let modelsDir = OsmAndApp.swiftInstance().documentsPath.appendingPathComponent(MODEL_3D_DIR)
            let modelsDirs = try FileManager.default.contentsOfDirectory(atPath: modelsDir)
            if !modelsDirs.isEmpty {
                for model in modelsDirs {
                    if isModelExist(dir: modelsDir.appendingPathComponent(model)) {
                        modelsDirNames.append(MODEL_NAME_PREFIX + model)
                    }
                }
            }
        } catch let error {
            debugPrint(error)
        }
        return modelsDirNames
    }
    
    static func isModelExist(dir: String) -> Bool {
        do {
            var isDir = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: dir, isDirectory: &isDir)
            guard exists && isDir.boolValue else { return false }
            
            let modelFiles = try FileManager.default.contentsOfDirectory(atPath: dir)
            if !modelFiles.isEmpty {
                for file in modelFiles {
                    if file.hasSuffix(OBJ_FILE_EXT) {
                        return true
                    }
                }
            }
        } catch let error {
            debugPrint(error)
        }
        return false
    }
}
