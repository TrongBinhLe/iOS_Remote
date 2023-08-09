//
//  PageAppObject.swift
//  Remote
//
//  Created by admin on 09/08/2023.
//


import Foundation
import RealmSwift

class PageAppObject: Object {
    override public class func primaryKey() -> String? {
        return "deviceId"
    }
    
    @objc dynamic var deviceId: String = ""
    var apps = List<AppObject>()
}
