//
//  Maintainer+SetsPostgres.swift
//  ManaKit_Example
//
//  Created by Vito Royeca on 10/26/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Kanna
import PostgresClientKit
import PromiseKit

extension Maintainer {
    func createSetBlockPromise(blockCode: String, block: String) -> Promise<Void> {
        let nameSection = self.sectionFor(name: block) ?? "NULL"
        
        let query = "SELECT createOrUpdateSetBlock($1,$2,$3)"
        let parameters = [blockCode,
                          block,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }

    func createSetTypePromise(setType: String) -> Promise<Void> {
        let capName = capitalize(string: self.displayFor(name: setType))
        let nameSection = self.sectionFor(name: setType) ?? "NULL"
        
        let query = "SELECT createOrUpdateSetType($1,$2)"
        let parameters = [capName,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func createSetPromise(dict: [String: Any]) -> Promise<Void> {
        let cardCount = dict["card_count"] as? Int ?? Int(0)
        let code = dict["code"] as? String ?? "NULL"
        let isFoilOnly = dict["foil_only"] as? Bool ?? false
        let isOnlineOnly = dict["digital"] as? Bool ?? false
        let mtgoCode = dict["mtgo_code"] as? String ?? "NULL"
        let keyruneUnicode = dict["keyrune_unicode"] as? String ?? "NULL"
        let keyruneClass = dict["keyrune_class"] as? String ?? "NULL"
        var myNameSection = "NULL"
        if let name = dict["name"] as? String {
            myNameSection = sectionFor(name: name) ?? "NULL"
        }
        var myYearSection = "Undated"
        if let releaseDate = dict["released_at"] as? String {
            myYearSection = String(releaseDate.prefix(4))
        }
        let name = dict["name"] as? String ?? "NULL"
        let releaseDate = dict["released_at"] as? String ?? "NULL"
        let tcgplayerId = dict["tcgplayer_id"] as? Int ?? Int(0)
        let cmsetblock = dict["block_code"] as? String ?? "NULL"
        var setTypeCap = "NULL";
        if let setType = dict["set_type"] as? String {
            setTypeCap = capitalize(string: self.displayFor(name: setType))
        }
        let setParent = dict["parent_set_code"] as? String ?? "NULL"
        
        let query = "SELECT createOrUpdateSet($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)"
        let parameters = [cardCount,
                          code,
                          isFoilOnly,
                          isOnlineOnly,
                          mtgoCode,
                          keyruneUnicode,
                          keyruneClass,
                          myNameSection,
                          myYearSection,
                          name,
                          releaseDate,
                          tcgplayerId,
                          cmsetblock,
                          setTypeCap,
                          setParent] as [Any]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func updatedKeyruneCodes() -> [[String: String]] {
        let document = keyruneCodes()
        var keyrunes = [String: [String: String]]()
        
        for div in document.xpath("//div[@class='vectors']") {
            for span in div.xpath("//span") {
                if let content = span.content {
                    let components = content.components(separatedBy: " ")
                    
                    if components.count == 3 {
                        let keyruneClass = components[1].replacingOccurrences(of: "ss-", with: "")
                        let keyruneUnicode = components[2].replacingOccurrences(of: "&#x", with: "").replacingOccurrences(of: ";", with: "")
                        keyrunes[keyruneClass] = ["keyrune_unicode": keyruneUnicode,
                                                  "keyrune_class": keyruneClass]
                    }
                }
            }
        }
        
        let keyruneUpdates = keyruneUpdates()
        keyrunes = keyrunes.merging(keyruneUpdates) { (_, new) in new }
        
        return keyrunes.map({
            ["code": $0.key,
             "keyrune_unicode": $0.value["keyrune_unicode"] ?? "",
             "keyrune_class": $0.value["keyrune_class"] ?? ""]
        })
    }
    
    private func keyruneCodes() -> HTMLDocument {
        let keyrunePath = "\(cachePath)/\(filePrefix)_\(keyruneFileName)"
        let url = URL(fileURLWithPath: keyrunePath)
        
        return try! HTML(url: url, encoding: .utf8)
    }
    
    private func keyruneUpdates() -> [String: [String: String]] {
        if let url = Bundle.module.url(forResource: "keyrune-updates", withExtension: "plist") {
            let data = try! Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            return try! decoder.decode([String: [String: String]].self, from: data)
        } else {
            return [:]
        }
    }
}
