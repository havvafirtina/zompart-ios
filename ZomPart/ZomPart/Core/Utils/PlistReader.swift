//
//  PlistReader.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct PlistReader {

    static func value<T>(for key: String) -> T {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? T else {
            fatalError("The key '\(key)' was not found in the Info.plist or is not of type \(T.self).")
        }
        return value
    }
}
