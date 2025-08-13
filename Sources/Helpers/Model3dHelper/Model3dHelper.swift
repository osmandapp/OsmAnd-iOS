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
        lock.lock()
        
        let pureModelName = modelName.lastPathComponent().replacingOccurrences(of: MODEL_NAME_PREFIX, with: "")
        if !modelName.hasPrefix(MODEL_NAME_PREFIX) {
            processCallback(modelName: pureModelName, model: nil, callback: callback)
            
            lock.unlock()
            return nil
        }
        
        let model3D = modelsCache[pureModelName]
        if model3D == nil {
            loadModelImpl(modelName: pureModelName, callback: callback)
        }
        
        lock.unlock()
        return model3D
    }

    func loadAllModels(callback: OAModel3dCallback?) {
        let modelDirPaths = Model3dHelper.listModels()
        if !modelDirPaths.isEmpty {
            var loadingsCount = modelDirPaths.count
            for modelDirPath in modelDirPaths {
                getModel(modelName: modelDirPath, callback: OAModel3dCallback { model in
                    loadingsCount -= 1
                    if loadingsCount == 0 {
                        callback?.processResult(model)
                    }
                })
            }
        }
    }

    private func processCallback(modelName: String, model: OAModel3dWrapper?, callback: OAModel3dCallback?) {
        if let callback {
            DispatchQueue.global(qos: .default).async {
                callback.processResult(model)
            }
            if let callbacks = self.pendingCallbacks[modelName] {
                self.pendingCallbacks.removeValue(forKey: modelName)
                if !callbacks.isEmpty {
                    DispatchQueue.global(qos: .default).async {
                        for pendingCallback in callbacks where pendingCallback != callback {
                            pendingCallback.processResult(model)
                        }
                    }
                }
            }
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
            if let callback = callback {
                if var callbacks = pendingCallbacks[modelName] {
                    callbacks.append(callback)
                    pendingCallbacks[modelName] = callbacks
                } else {
                    pendingCallbacks[modelName] = [callback]
                }
            }
            return
        }
        
        let modelDir = OsmAndApp.swiftInstance().models3dPath.appendingPathComponent(modelName)
        if !Model3dHelper.isModelExist(dir: modelDir) {
            processCallback(modelName: modelName, model: nil, callback: callback)
            return
        }
        
        modelsInProgress.insert(modelName)
        
        let task = OALoad3dModelTask(modelDir) { [weak self] model in
            guard let strongSelf = self else { return false }
            strongSelf.lock.lock()

            if model == nil {
                strongSelf.failedModels.insert(modelName)
            } else {
                strongSelf.modelsCache[modelName] = model
            }
            strongSelf.modelsInProgress.remove(modelName)
            strongSelf.processCallback(modelName: modelName, model: model, callback: callback)

            strongSelf.lock.unlock()
            return true
        }
        task?.execute()
    }
    
    static func listModels() -> [String] {
        var res = [String]()
        do {
            let modelsDir: String = OsmAndApp.swiftInstance().models3dPath
            let modelsDirs = try FileManager.default.contentsOfDirectory(atPath: modelsDir)
            if !modelsDirs.isEmpty {
                for modelDirName in modelsDirs {
                    let dirPath = modelsDir.appendingPathComponent(modelDirName)
                    if isModelExist(dir: dirPath) {
                        res.append(MODEL_NAME_PREFIX + modelDirName)
                    }
                }
            }
        } catch let error {
            debugPrint(error)
        }
        return res
    }
    
    static func getCustomModelNames() -> [String] {
        var res = [String]()
        let defaultIconModels = OALocationIcon.defaultIconModels()
        do {
            let modelsDir: String = OsmAndApp.swiftInstance().models3dPath
            let modelsDirs = try FileManager.default.contentsOfDirectory(atPath: modelsDir)
            if !modelsDirs.isEmpty {
                for modelDirName in modelsDirs {
                    let dirPath = modelsDir.appendingPathComponent(modelDirName)
                    let name = MODEL_NAME_PREFIX + modelDirName
                    if isModelExist(dir: dirPath) && !defaultIconModels.contains(name) {
                        res.append(name)
                    }
                }
            }
        } catch let error {
            debugPrint(error)
        }
        return res
    }
    
    static func getModelPath(modelName: String) -> String {
        return OsmAndApp.swiftInstance().models3dPath.appendingPathComponent(modelName)
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
                for file in modelFiles where file.hasSuffix(OBJ_FILE_EXT) {
                    return true
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
