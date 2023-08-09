//  RemoteRealm.swift - TVController2
//  Copyright © 2023 Samsung Electronics. All rights reserved.

import Foundation
import RealmSwift
import ReactiveSwift
import ReactiveCocoa

class RemoteRealm {
    /// The model version
    private static let schemaVersion: UInt64 = 1
    private static let config = Realm.Configuration(fileURL: realmFile(), schemaVersion: schemaVersion, migrationBlock: migrationBlock, deleteRealmIfMigrationNeeded: true, objectTypes: [PageAppObject.self, PageSoundAndAppObject.self, AppObject.self, RemoteSettingObject.self, PageLayoutObject.self])
    
    private let scheduler = QueueScheduler(qos: .default, name: "Queue.RemoteRealm")

    private static func realmFile() -> URL? {
        if let documentDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            CLLogDebug(.REMOTE, "realm file: \(documentDirectory)")
            return documentDirectory.appendingPathComponent("remote.realm")
        }
        return Realm.Configuration.defaultConfiguration.fileURL
    }

    private static let migrationBlock: MigrationBlock = { (migration, size) in
    }

    private func getRealm() -> Realm? {
        do {
            let realm = try Realm(configuration: RemoteRealm.config)
            return realm
        } catch {
            CLLogDebug(.REMOTE, "❌ getRealm error :\(error)")
            return nil
        }
    }
    
    func savePageApp(item: FirstScreenDetailItem, deviceId: String) {
        guard let realm = getRealm() else {
            return
        }
        
        guard let object = realm.object(ofType: PageAppObject.self, forPrimaryKey: deviceId) else {
            try? realm.write {
                let object = PageAppObject()
                object.deviceId = deviceId
                object.apps.append(AppObject(item: item))
                
                realm.add(object, update: .all)
            }
            return
        }

        try? realm.write {
            object.apps.append(AppObject(item: item))
            CLLogDebug(.REMOTE, "completed - key: \(deviceId), id: \(item.id)")
        }
    }
    
    func checkPageCreated(deviceId: String) -> Bool {
        guard let realm = getRealm() else {
            return false
        }
        
        if let _ = realm.object(ofType: PageAppObject.self, forPrimaryKey: deviceId) {
            return true
        }
        
        return false
    }
    
    func removePageApp(deviceId: String, item: FirstScreenDetailItem) {
        guard let realm = getRealm() else {
            return
        }
        
        if let object = realm.object(ofType: PageAppObject.self, forPrimaryKey: deviceId)?.apps.filter("id = %@", item.id).first {
            try? realm.write {
                realm.delete(object)
            }
        }

        if let object = realm.object(ofType: PageSoundAndAppObject.self, forPrimaryKey: deviceId)?.apps.filter("id = %@", item.id).first {
            try? realm.write {
                realm.delete(object)
            }
        }
    }
    
    func removePageApp(deviceId: String, items: [FirstScreenDetailItem]) {
        guard let realm = getRealm() else {
            return
        }
        
        if let object = realm.object(ofType: PageAppObject.self, forPrimaryKey: deviceId) {
            for item in items {
                if let itemObject = object.apps.filter("id = %@", item.id).first {
                    try? realm.write {
                        realm.delete(itemObject)
                    }
                }
            }
        }
    }
    
    func removePageSoundAndApp(deviceId: String, items: [FirstScreenDetailItem]) {
        guard let realm = getRealm() else {
            return
        }
        
        if let object = realm.object(ofType: PageSoundAndAppObject.self, forPrimaryKey: deviceId) {
            for item in items {
                if let itemObject = object.apps.filter("id = %@", item.id).first {
                    try? realm.write {
                        realm.delete(itemObject)
                    }
                }
            }
        }
    }
    
    func savePageSoundAndApp(item: FirstScreenDetailItem, deviceId: String) {
        guard let realm = getRealm() else {
            return
        }

        guard let object = realm.object(ofType: PageSoundAndAppObject.self, forPrimaryKey: deviceId) else {
            try? realm.write {
                let object = PageSoundAndAppObject()
                object.deviceId = deviceId
                object.apps.append(AppObject(item: item))
                
                realm.add(object, update: .all)
            }
            return
        }

        try? realm.write {
            object.apps.append(AppObject(item: item))
            CLLogDebug(.REMOTE, "completed - key: \(deviceId), id: \(item.id)")
        }
    }
    
    func checkPageSoundAndAppCreated(deviceId: String) -> Bool {
        guard let realm = getRealm() else {
            return false
        }
        
        if let _ = realm.object(ofType: PageSoundAndAppObject.self, forPrimaryKey: deviceId) {
            return true
        }
        
        return false
    }
    
    func getListForPageApp(deviceId: String) -> SignalProducer<[FirstScreenDetailItem], TraceError> {
        return SignalProducer<[FirstScreenDetailItem], TraceError>() { [weak self] observer, _ in
            guard let `self` = self else {
                observer.sendCompleted()
                return
            }
            
            guard let realm = self.getRealm() else {
                observer.sendCompleted()
                return
            }
            
            guard let object = realm.object(ofType: PageAppObject.self, forPrimaryKey: deviceId) else {
                observer.send(value: [])
                observer.sendCompleted()
                return
            }
            
            let items = Array(object.apps).map { $0.toFirstScreenDetailItem() }
            
            observer.send(value: items)
            observer.sendCompleted()
        }
    }
    
    func getListForPageSoundAndApp(deviceId: String) -> SignalProducer<[FirstScreenDetailItem], TraceError> {
        return SignalProducer<[FirstScreenDetailItem], TraceError>() { [weak self] observer, _ in
            guard let `self` = self else {
                observer.sendCompleted()
                return
            }
            
            guard let realm = self.getRealm() else {
                observer.sendCompleted()
                return
            }
            
            guard let object = realm.object(ofType: PageSoundAndAppObject.self, forPrimaryKey: deviceId) else {
                observer.send(value: [])
                observer.sendCompleted()
                return
            }
            
            let items = Array(object.apps).map { $0.toFirstScreenDetailItem() }
            
            observer.send(value: items)
            observer.sendCompleted()
        }
    }
    
    func getAll(deviceId: String) -> SignalProducer<[FirstScreenDetailItem], TraceError> {
        return SignalProducer.combineLatest(
            self.getListForPageApp(deviceId: deviceId),
            self.getListForPageSoundAndApp(deviceId: deviceId)
        )
        .observe(on: self.scheduler)
        .map { result -> [FirstScreenDetailItem] in
            return (result.0 + result.1).removingDuplicates(byKey: { $0.id })
        }
    }
    
    func saveRemoteSetting(deviceId: String, isEnableTouchPad: Bool?, pageIndex: Int?) {
        guard let realm = getRealm() else {
            return
        }
        
        guard let object = realm.object(ofType: RemoteSettingObject.self, forPrimaryKey: deviceId) else {
            let object = RemoteSettingObject()
            object.deviceId = deviceId
            
            if let isEnable = isEnableTouchPad {
                object.isEnableTouchPad = isEnable
            }
            
            if let pageIndex = pageIndex {
                object.pageIndex = pageIndex
            }
            
            try? realm.write {
                realm.add(object, update: .all)
            }
            
            return
        }

        try? realm.write {
            if let isEnable = isEnableTouchPad {
                object.isEnableTouchPad = isEnable
            }
            
            if let pageIndex = pageIndex {
                object.pageIndex = pageIndex
            }
        }
    }
    
    func saveRemoteSetting(deviceId: String, pageLayouts: [PageCellViewModel]) {
        guard let realm = getRealm() else {
            return
        }
        
        guard let object = realm.object(ofType: RemoteSettingObject.self, forPrimaryKey: deviceId) else {
            let object = RemoteSettingObject()
            object.deviceId = deviceId
            object.pageLayouts.append(objectsIn: pageLayouts.map { PageLayoutObject(page: $0) })
            
            try? realm.write {
                realm.add(object, update: .all)
            }
            
            return
        }
        
        try? realm.write {
            object.pageLayouts.removeAll()
            object.pageLayouts.append(objectsIn: pageLayouts.map { PageLayoutObject(page: $0) })
        }
    }
    
    func getRemoteSetting(deviceId: String) -> SignalProducer<(Bool?, Int?, [PageCellViewModel]), Never> {
        return SignalProducer<(Bool?, Int?, [PageCellViewModel]), Never>() { [weak self] observer, _ in
            guard let `self` = self else {
                observer.sendCompleted()
                return
            }
            
            guard let realm = self.getRealm() else {
                observer.sendCompleted()
                return
            }
            
            guard let object = realm.object(ofType: RemoteSettingObject.self, forPrimaryKey: deviceId) else {
                observer.send(value: (nil, nil, []))
                observer.sendCompleted()
                return
            }
            
            observer.send(value: object.toRemoteSetting())
            observer.sendCompleted()
        }
    }
    
    func cleanData(deviceId: String) {
        guard let realm = getRealm() else {
            return
        }
        
        try? realm.write {
            if let settingObject = realm.object(ofType: RemoteSettingObject.self, forPrimaryKey: deviceId) {
                realm.delete(settingObject)
            }
            
            if let pageObject = realm.object(ofType: PageAppObject.self, forPrimaryKey: deviceId) {
                realm.delete(pageObject)
            }
            
            if let soundAndPageObject = realm.object(ofType: PageSoundAndAppObject.self, forPrimaryKey: deviceId) {
                realm.delete(soundAndPageObject)
            }
        }
    }
}
