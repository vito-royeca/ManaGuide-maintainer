//
//  Maintainer+Sets.swift
//  ManaKit_Example
//
//  Created by Jovito Royeca on 23/10/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import PostgresClientKit
import PromiseKit

extension Maintainer {
    func processSetsData() -> Promise<Void> {
        return Promise { seal in
            let label = "processSetsData"
            let date = self.startActivity(label: label)
            var promises = [()->Promise<Void>]()
            
            promises.append(contentsOf: self.filterSetBlocks(array: setsArray))
            promises.append(contentsOf: self.filterSetTypes(array: setsArray))
            promises.append(contentsOf: self.filterSets(array: setsArray))
            promises.append(contentsOf: self.createKeyrunePromises(array: setsArray))

            let completion = {
                self.endActivity(label: label, from: date)
                seal.fulfill(())
            }
            self.execInSequence(label: label,
                                promises: promises,
                                completion: completion)
        }
    }
    
    func setsData() -> [[String: Any]] {
        let setsPath = "\(cachePath)/\(ManaKit.Constants.ScryfallDate)_\(setsFileName)"
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: setsPath))
        guard let dict = try! JSONSerialization.jsonObject(with: data,
                                                           options: .mutableContainers) as? [String: Any] else {
            fatalError("Malformed data")
        }
        guard let array = dict["data"] as? [[String: Any]] else {
            fatalError("Malformed data")
        }
        
        return array
    }

    func filterSetBlocks(array: [[String: Any]]) -> [()->Promise<Void>] {
        var filteredData = [String: String]()
        
        for dict in array {
            if let blockCode = dict["block_code"] as? String,
                let block = dict["block"] as? String {
                filteredData[blockCode] = block
            }
        }
        let promises: [()->Promise<Void>] = filteredData.map { (blockCode, block) in
            return {
                return self.createSetBlockPromise(blockCode: blockCode,
                                                  block: block)
            }
        }
        return promises
    }
    
    func filterSetTypes(array: [[String: Any]]) -> [()->Promise<Void>] {
        var filteredData = Set<String>()
        
        for dict in array {
            if let setType = dict["set_type"] as? String {
                filteredData.insert(setType)
            }
        }
        let promises: [()->Promise<Void>] = filteredData.map { setType in
            return {
                return self.createSetTypePromise(setType: setType)
            }
        }
        return promises
    }
    
    func filterSets(array: [[String: Any]]) -> [()->Promise<Void>] {
        let filteredData = array.sorted(by: {
            $0["parent_set_code"] as? String ?? "" < $1["parent_set_code"] as? String ?? ""
        })
        
        let promises: [()->Promise<Void>] = filteredData.map { dict in
            return {
                return self.createSetPromise(dict: dict)
            }
        }
        
        return promises
    }
}
