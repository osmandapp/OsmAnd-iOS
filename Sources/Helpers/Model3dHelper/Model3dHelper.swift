//
//  Model3dHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 21/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

typealias callbackWithModel3d = (_ model: OAModel3dWrapper?) -> Void

@objcMembers
final class Model3dHelper: NSObject {
    
    static let shared = Model3dHelper()
    
    private let app: OsmAndAppProtocol
    private let settings: OAAppSettings
    
    private var modelsCache = [String: OAModel3dWrapper]()
    private var modelsInProgress = Set<String>()
    private var failedModels = Set<String>()
    private var pendingCallbacks = [String: [OAModel3dCallback]]()
    
    private override init() {
        app = OsmAndApp.swiftInstance()
        settings = OAAppSettings.sharedManager()
    }
    
    func getModel(modelName: String, callback: OAModel3dCallback?) -> OAModel3dWrapper? {
        let pureModelName = modelName.replacingOccurrences(of: MODEL_NAME_PREFIX, with: "")
        
        if !modelName.hasPrefix(MODEL_NAME_PREFIX) {
            processCallback(modelName: pureModelName, model: nil, callback: callback)
            return nil
        }
        
        let model3D = modelsCache[pureModelName]
        if model3D == nil {
            loadModel(modelName: pureModelName, callback: callback)
        }
        
        return model3D
    }
    
    private func loadModel(modelName: String, callback: OAModel3dCallback?) {
        DispatchQueue.main.async { [weak self] in
            self?.loadModelImpl(modelName: modelName, callback: callback)
        }
    }
    
    private func processCallback(modelName: String, model: OAModel3dWrapper?, callback: OAModel3dCallback?) {
        if let callback {
            if let callbacks = pendingCallbacks[modelName] {
                if let index = callbacks.firstIndex(of: callback) {
                    self.pendingCallbacks[modelName]?.remove(at: index)
                    if !callbacks.isEmpty {
                        for pendingCallback in callbacks {
                            pendingCallback.processResult(model)
                        }
                    }
                    self.pendingCallbacks.removeValue(forKey: modelName)
                }
            }
            callback.processResult(model)
        }
    }
    
    private func loadModelImpl(modelName: String, callback: OAModel3dCallback?) {
        if let model = modelsCache[modelName] {
            processCallback(modelName: modelName, model: model, callback: callback)
            return
        }
        if failedModels.contains(modelName) {
            processCallback(modelName: modelName, model: nil, callback: callback)
            return
        }
        if modelsInProgress.contains(modelName) {
            if let callback {
                if pendingCallbacks[modelName] == nil {
                    pendingCallbacks[modelName] = Array<OAModel3dCallback>()
                    pendingCallbacks[modelName]?.append(callback)
                }
            }
            return
        }
        
        let task = OALoad3dModelTask(modelName) { [weak self] model in
            if model == nil {
                self?.failedModels.insert(modelName)
            } else {
                self?.modelsCache[modelName] = model
            }
            self?.modelsInProgress.remove(modelName)
            self?.processCallback(modelName: modelName, model: model, callback: callback)
            if let callback {
                callback.processResult(model)
            }
            return true
        }
        
        if let task {
            if !Model3dHelper.isModelExist(dir: task.modelDirPath) {
                processCallback(modelName: modelName, model: nil, callback: callback)
                return
            }
            modelsInProgress.insert(modelName)
            task.execute()
        }
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

@objcMembers
final class OAModel3dCallback: NSObject {
    private var callback: callbackWithModel3d?
    
    init(callback: callbackWithModel3d?) {
        super.init()
        self.callback = callback
    }
    
    func processResult(_ model: OAModel3dWrapper?) {
        callback?(model)
    }
}
