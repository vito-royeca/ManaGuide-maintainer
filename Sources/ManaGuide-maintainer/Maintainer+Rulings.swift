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
    func processRulingsData() -> Promise<Void> {
        return Promise { seal in
            let label = "processRulingsData"
            let date = self.startActivity(label: label)
            var promises = [()->Promise<Void>]()

            promises.append({
                return self.createDeleteRulingsPromise()

            })
            promises.append(contentsOf: rulingsArray.map { dict in
                return {
                    return self.createRulingPromise(dict: dict)
                }
            })

            let completion = {
                self.endActivity(label: label, from: date)
                seal.fulfill(())
            }
            self.execInSequence(label: label,
                                promises: promises,
                                completion: completion)
        }
    }
    
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
