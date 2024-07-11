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
    
    static let pluginId = "model.plugin"
    
    private var modelsCache = [String: OAModel3dWrapper]()
    private var modelsInProgress = Set<String>()
    private var failedModels = Set<String>()
    private var pendingCallbacks = [String: [OAModel3dCallback]]()
    private var isIniting = false
    private let lock = NSLock()
    
    private override init() {
    }
    
    func getModel(modelName: String, callback: OAModel3dCallback?) -> OAModel3dWrapper? {
        let dirs = Model3dHelper.listModelsWithNames()
        if let modelDirPath = dirs[modelName] {
            return getModel(modelDirPath: modelDirPath, callback: callback)
        }
        return nil
    }
    
    func getModel(modelDirPath: String, callback: OAModel3dCallback?) -> OAModel3dWrapper? {
        //FIXME: lock.lock()
        let pureModelName = Model3dHelper.getPureModelName(modelPath: modelDirPath)
        
        if !modelDirPath.lastPathComponent().hasPrefix(MODEL_NAME_PREFIX) && modelDirPath.length == pureModelName.length {
            processCallback(modelName: pureModelName, model: nil, callback: callback)
            //FIXME: lock.unlock()
            return nil
        }
        
        let model3D = modelsCache[pureModelName]
        if model3D == nil {
            loadModel(modelDirPath: modelDirPath, callback: callback)
        }
        
        //FIXME: lock.unlock()
        return model3D
    }
    
    static func getPureModelName(modelPath: String) -> String {
        modelPath.lastPathComponent().replacingOccurrences(of: MODEL_NAME_PREFIX, with: "")
    }

    func loadAllModels(callback: OAModel3dCallback?) {
        let modelDirPaths = Model3dHelper.listModels()
        if !modelDirPaths.isEmpty {
            var loadingsCount = modelDirPaths.count
            
            for modelDirPath in modelDirPaths {
                getModel(modelDirPath: modelDirPath, callback: OAModel3dCallback { model in
                    loadingsCount -= 1
                    if loadingsCount == 0 {
                        callback?.processResult(model)
                    }
                })
            }
        }
    }
    
    private func loadModel(modelDirPath: String, callback: OAModel3dCallback?) {
        self.loadModelImpl(modelDirPath: modelDirPath, callback: callback)
    }
    
    private func processCallback(modelName: String, model: OAModel3dWrapper?, callback: OAModel3dCallback?) {
        if let callback {
            if let callbacks = self.pendingCallbacks[modelName] {
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
    
    private func loadModelImpl(modelDirPath: String, callback: OAModel3dCallback?) {
        let modelName = Model3dHelper.getPureModelName(modelPath: modelDirPath)
        if let model = modelsCache[modelName] {
            processCallback(modelName: modelName, model: model, callback: callback)
            return
        }
        if failedModels.contains(modelName) {
            processCallback(modelName: modelName, model: nil, callback: callback)
            return
        }
        if modelsInProgress.contains(modelName) {
            if let callback, pendingCallbacks[modelName] == nil {
                pendingCallbacks[modelName] = Array<OAModel3dCallback>()
                pendingCallbacks[modelName]?.append(callback)
            }
            return
        }
        
        let modelFilePath = Model3dHelper.getModelObjFilePath(dirPath: modelDirPath)
        if !Model3dHelper.isModelFileExist(path: modelFilePath) {
            processCallback(modelName: modelName, model: nil, callback: callback)
            return
        }
        
        modelsInProgress.insert(modelName)
        
        let task = OALoad3dModelTask(modelDirPath) { [weak self] model in
            
            //FIXME: strongSelf.lock.lock()
            guard let strongSelf = self else { return false }
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                
                if model == nil {
                    strongSelf.failedModels.insert(modelName)
                } else {
                    strongSelf.modelsCache[modelName] = model
                }
                strongSelf.modelsInProgress.remove(modelName)
                strongSelf.processCallback(modelName: modelName, model: model, callback: callback)
            }
            
            //FIXME: strongSelf.lock.unlock()
            return true
        }
        task?.execute()
    }
    
    static func listModels() -> [String] {
        return Array(listModelsWithNames().values)
    }
    
    static func listModelsWithNames() -> [String: String] {
        var modelsDirPaths = [String: String]()
        
        let embeddedModels = listEmbeddedModelsWithNames()
        embeddedModels.map { modelsDirPaths[$0.key] = $0.value }
        
        // if online-plugin has a file with the same name like a embedded one, use it instead
        let pluginModels = listPluginModelsWithNames()
        pluginModels.map { modelsDirPaths[$0.key] = $0.value }
        
        // ("map_default_location" : "...Data/Documents/models/map_default_location/map_default_location")
        return modelsDirPaths
    }
    
    static func listEmbeddedModelsWithNames() -> [String: String] {
        var modelsDirPaths = [String: String]()
        do {
            if let embeddedModelsDirPath = getEmbeddedModelsDirParh() {
                let modelsDirs = try FileManager.default.contentsOfDirectory(atPath: embeddedModelsDirPath)
                if !modelsDirs.isEmpty {
                    for modelDirName in modelsDirs {
                        let dirPath = embeddedModelsDirPath.appendingPathComponent(modelDirName)
                        if isModelExist(dir: dirPath) {
                            let name = MODEL_NAME_PREFIX + modelDirName
                            modelsDirPaths[name] = dirPath
                        }
                    }
                }
            }
        } catch let error {
            debugPrint(error)
        }
        return modelsDirPaths
    }
    
    static func listPluginModelsWithNames() -> [String: String] {
        var modelsDirPaths = [String: String]()
        if let plugin = OAPluginsHelper.getPluginById(pluginId), plugin.isEnabled() {
            do {
                let pluginModelsDir = OsmAndApp.swiftInstance().documentsPath.appendingPathComponent(MODEL_3D_DIR)
                let modelsDirs = try FileManager.default.contentsOfDirectory(atPath: pluginModelsDir)
                if !modelsDirs.isEmpty {
                    for modelDirName in modelsDirs {
                        let dirPath = pluginModelsDir.appendingPathComponent(modelDirName)
                        if isModelExist(dir: dirPath) {
                            let name = MODEL_NAME_PREFIX + modelDirName
                            modelsDirPaths[name] = dirPath
                        }
                    }
                }
            } catch let error {
                debugPrint(error)
            }
        }
        return modelsDirPaths
    }
    
    static func getEmbeddedModelsDirParh() -> String? {
        if let appBundlePath = Bundle.main.resourcePath {
            return appBundlePath.appendingPathComponent(MODEL_3D_DIR)
        }
        return nil
    }
    
    static func getModelObjFilePath(dirPath: String) -> String {
        let name = dirPath.lastPathComponent()
        return dirPath.appendingPathComponent(name).appendingPathExtension("obj")
    }
    
    static func getModelIconFilePath(dirPath: String) -> String {
        let name = dirPath.lastPathComponent()
        return dirPath.appendingPathComponent(name).appendingPathExtension("png")
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
    
    static func isModelFileExist(path: String) -> Bool {
        let exists = FileManager.default.fileExists(atPath: path)
        return exists && path.hasSuffix(OBJ_FILE_EXT)
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
