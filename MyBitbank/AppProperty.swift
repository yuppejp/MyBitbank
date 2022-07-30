//
//  AppProperty.swift
//  MyBitbank
//  
//  Created on 2022/07/30
//  
//

import Foundation

struct AppProperty {

    private let resourcePath = Bundle.main.path(forResource: "AppProperty", ofType: "plist")

    func getKeys() -> NSDictionary? {
        guard let path = resourcePath else {
            return nil
        }
        return NSDictionary(contentsOfFile: path)
    }

    func getValue(_ key: String) -> AnyObject? {
        guard let keys = getKeys() else {
            return nil
        }
        return keys[key]! as AnyObject
    }

    func getStringValue(_ key: String) -> String {
        guard let keys = getKeys() else {
            return ""
        }
        guard let value = keys[key] as? String else {
            return ""
        }
        return value
    }
}
