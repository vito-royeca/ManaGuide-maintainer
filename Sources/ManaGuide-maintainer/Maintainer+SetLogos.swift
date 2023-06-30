//
//  File.swift
//  
//
//  Created by Vito Royeca on 7/18/22.
//

import Foundation
import PromiseKit

extension Maintainer {
    func downloadSetLogos() -> Promise<Void> {
        return Promise { seal in
            let label = "downloadSetLogos"
            let date = self.startActivity(label: label)
            let completion = {
                self.endActivity(label: label, from: date)
                seal.fulfill(())
            }
            let setsPath = imagesPath.replacingOccurrences(of: "cards", with: "sets")
            var promises = [()->Promise<Void>]()
            
            for keyrune in updatedKeyruneCodes() {
                if let logoCode = keyrune["logo_code"],
                    logoCode != "null" {
                    
                    let destSmall = "\(setsPath)/\(logoCode)_small.png"
                    if !FileManager.default.fileExists(atPath: destSmall) {
                        print(destSmall)
                        let sourceSmall = "https://www.mtgpics.com/graph/sets/logos/" + logoCode + ".png"
                        promises.append({ return self.downloadImagePromise(url: sourceSmall, destinationFile: destSmall) })
                    }
                    
                    let destBig = "\(setsPath)/\(logoCode)_big.png"
                    if !FileManager.default.fileExists(atPath: destBig) {
                        print(destBig)
                        let sourceBig = "https://www.mtgpics.com/graph/sets/logos_big/" + logoCode + ".png"
                        promises.append({ return self.downloadImagePromise(url: sourceBig, destinationFile: destBig) })
                    }
                }
            }
            
            self.execInSequence(label: label,
                                promises: promises,
                                completion: completion)
        }
    }
}
