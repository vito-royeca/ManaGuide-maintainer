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
            guard let url = Bundle.module.url(forResource: "mtgpics", withExtension: "json") else {
                print("mtgpics.json not found")
                seal.fulfill()
                return
            }

            do {
                let data = try Data(contentsOf: url)
                let array = try JSONDecoder().decode([String].self, from: data)
                let label = "downloadSetLogos"
                let date = self.startActivity(label: label)
                let completion = {
                    self.endActivity(label: label, from: date)
                    seal.fulfill(())
                }
                let setsPath = imagesPath.replacingOccurrences(of: "cards", with: "sets")
                var promises = [()->Promise<Void>]()
                
                for code in array {
                    let sourceSmall = "https://www.mtgpics.com/graph/sets/logos/" + code + ".png"
                    let destSmall = "\(setsPath)/\(code)_small.png"
                    if !FileManager.default.fileExists(atPath: destSmall) {
                        print(destSmall)
                        promises.append({ return self.downloadImagePromise(url: sourceSmall, destinationFile: destSmall) })
                    }
                    
                    let sourceBig = "https://www.mtgpics.com/graph/sets/logos_big/" + code + ".png"
                    let destBig = "\(setsPath)/\(code)_big.png"
                    if !FileManager.default.fileExists(atPath: destBig) {
                        print(destBig)
                        promises.append({ return self.downloadImagePromise(url: sourceBig, destinationFile: destBig) })
                    }
                }

                self.execInSequence(label: label,
                                    promises: promises,
                                    completion: completion)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    
}
