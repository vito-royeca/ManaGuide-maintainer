//
//  Maintainer+Rulings.swift
//  ManaKit_Example
//
//  Created by Jovito Royeca on 14/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import PromiseKit

extension Maintainer {
    func rulingsData() -> [[String: Any]] {
        let rulingsPath = "\(cachePath)/\(rulingsRemotePath.components(separatedBy: "/").last ?? "")"
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: rulingsPath))
        guard let array = try! JSONSerialization.jsonObject(with: data,
                                                            options: .mutableContainers) as? [[String: Any]] else {
            fatalError("Malformed data")
        }
        
        return array
    }
}
