//
//  Maintainer+SetsPostgres.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 10/26/19.
//

import Foundation
import Kanna
import PostgresClientKit

extension Maintainer {
    func createSetBlock(blockCode: String, block: String) async throws {
        let nameSection = self.sectionFor(name: block) ?? "NULL"
        
        let query = "SELECT createOrUpdateSetBlock($1,$2,$3)"
        let parameters = [blockCode,
                          block,
                          nameSection]
        try await exec(query: query, with: parameters)
    }

    func createSetType(setType: String) async throws {
        let capName = capitalize(string: self.displayFor(name: setType))
        let nameSection = self.sectionFor(name: setType) ?? "NULL"
        
        let query = "SELECT createOrUpdateSetType($1,$2)"
        let parameters = [capName,
                          nameSection]
        try await exec(query: query, with: parameters)
    }
    
    func createSet(dict: [String: Any]) async throws {
        let cardCount = dict["card_count"] as? Int ?? Int(0)
        let code = dict["code"] as? String ?? "NULL"
        let isFoilOnly = dict["foil_only"] as? Bool ?? false
        let isOnlineOnly = dict["digital"] as? Bool ?? false
        let logoCode = dict["logo_code"] as? String ?? "NULL"
        let mtgoCode = dict["mtgo_code"] as? String ?? "NULL"
        let keyruneUnicode = dict["keyrune_unicode"] as? String ?? "NULL"
        let keyruneClass = dict["keyrune_class"] as? String ?? "NULL"
        var nameSection = "NULL"
        if let name = dict["name"] as? String {
            nameSection = sectionFor(name: name) ?? "NULL"
        }
        var yearSection = "Undated"
        if let releaseDate = dict["released_at"] as? String {
            yearSection = String(releaseDate.prefix(4))
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
        
        let query = "SELECT createOrUpdateSet($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)"
        let parameters = [cardCount,
                          code,
                          isFoilOnly,
                          isOnlineOnly,
                          logoCode,
                          mtgoCode,
                          keyruneUnicode,
                          keyruneClass,
                          nameSection,
                          yearSection,
                          name,
                          releaseDate,
                          tcgplayerId,
                          cmsetblock,
                          setTypeCap,
                          setParent] as [Any]
        try await exec(query: query, with: parameters)
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
        let combinedKeyrunes = keyrunes.merging(keyruneUpdates) { (_, new) in new }
        
        return combinedKeyrunes.map({
            ["code": $0.key,
             "keyrune_unicode": $0.value["keyrune_unicode"] ?? "",
             "keyrune_class": $0.value["keyrune_class"] ?? "",
             "logo_code": $0.value["logo_code"] ?? "null"]
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
