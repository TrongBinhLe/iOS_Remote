//
//  AppObjet.swift
//  Remote
//
//  Created by admin on 09/08/2023.
//

import Foundation
import RealmSwift

class AppObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var iconPath: String = ""
    @objc dynamic var isSelected: Bool = false
    @objc dynamic var linkId: String = ""
    
    convenience init(item: FirstScreenDetailItem) {
        self.init()
        
        self.id = item.id
        self.title = item.title
        self.iconPath = item.iconPath
        self.isSelected = item.isSelected
        self.linkId = item.linkId
    }
    
    func toFirstScreenDetailItem() -> FirstScreenDetailItem {
        return FirstScreenDetailItem(
            id: id,
            iconPath: iconPath,
            title: title,
            type: .app(value: .defaultApp),
            isSelected: isSelected,
            linkId: linkId
        )
    }
}
