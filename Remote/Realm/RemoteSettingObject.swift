//
//  RemoteSettingObject.swift
//  Remote
//
//  Created by admin on 09/08/2023.
//

import Foundation
import RealmSwift

class RemoteSettingObject: Object {
    override public class func primaryKey() -> String? {
        return "deviceId"
    }
    
    @objc dynamic var deviceId: String = ""
    @objc dynamic var isEnableTouchPad: Bool = false
    @objc dynamic var pageIndex: Int = 2
    var pageLayouts = List<PageLayoutObject>()
    
    func toRemoteSetting() -> (Bool, Int, [PageCellViewModel]) {
        return (isEnableTouchPad, pageIndex, pageLayouts.map { $0.toPageCellViewModel() })
    }
}
