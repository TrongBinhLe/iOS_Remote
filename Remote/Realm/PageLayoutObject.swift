//
//  PageLayoutObject.swift
//  Remote
//
//  Created by admin on 09/08/2023.
//

import Foundation
import RealmSwift

class PageLayoutObject: Object {
    @objc dynamic var content: String = ""
    
    convenience init(page: PageCellViewModel) {
        self.init()
        
        self.content = page.content
    }
    
    func toPageCellViewModel() -> PageCellViewModel {
        return PageCellViewModel(content: content, type: convert(content: content) )
    }
    
    private func convert(content: String) -> PageLayoutType {
        switch content {
        case "abcd":
            return .abcd
        case "numPad":
            return .numPad
        case "tvControl":
            return .tvControl
        case "tvControlAndApplicationConfig":
            return .tvControlAndApplicationConfig
        case "applicationConfig":
            return .applicationConfig
        case "layout1":
            return .layout1
        case "layout2":
            return .layout2
        case "layout3":
            return .layout3
        case "layout4":
            return .layout4
        default:
            return .abcd
        }
    }
}

