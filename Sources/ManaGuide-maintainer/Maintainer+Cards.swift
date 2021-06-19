//
//  Maintainer+Cards.swift
//  ManaKit
//
//  Created by Jovito Royeca on 21.10.18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import PMJSON
import PostgresClientKit
import PromiseKit

extension Maintainer {
    func processCardsData() -> Promise<Void> {
        return Promise { seal in
            let cardsPath = "\(self.cachePath)/\(self.cardsRemotePath.components(separatedBy: "/").last ?? "")"
            let fileReader = StreamingFileReader(path: cardsPath)
            let label = "processCardsData"
            let date = self.startActivity(label: label)
            
            self.loopReadCards(fileReader: fileReader, start: 0, callback: {
                self.endActivity(label: label, from: date)
                seal.fulfill()
            })
        }
    }
    
    func loopReadCards(fileReader: StreamingFileReader, start: Int, callback: @escaping () -> Void) {
        let label = "createCards"
        let date = self.startActivity(label: label)
        let cards = self.readCardData(fileReader: fileReader, lines: self.printMilestone)
        
        if !cards.isEmpty {
            let index = start + cards.count
            var promises = [()->Promise<Void>]()
            
            if start == 0 {
                promises.append({
                    return self.createDeleteParts()
                })
                promises.append({
                    return self.createDeleteFaces()
                })
            }
            for card in cards {
                promises.append(contentsOf: self.createCardPromises(dict: card))
            }
            
            self.execInSequence(label: "\(label): \(index)",
                                promises: promises,
                                completion: {
                                    self.endActivity(label: "\(label): \(index)", from: date)
                                    
                                    self.loopReadCards(fileReader: fileReader, start: index, callback: callback)
                                    
            })
        } else {
            callback()
        }
    }
    
    func createCardPromises(dict: [String: Any]) -> [()->Promise<Void>] {
        var promises = [()->Promise<Void>]()
        
        if let artist = dict["artist"] as? String {
            if !artistsCache.contains(artist) {
                artistsCache.append(artist)
                
                promises.append({
                    return self.create(artist: artist)
                })
            }
        }
        
        if let rarity = dict["rarity"] as? String {
            if !raritiesCache.contains(rarity) {
                raritiesCache.append(rarity)
                
                promises.append({
                    return self.create(rarity: rarity)
                })
            }
        }
        
        if let language = filterLanguage(dict: dict) {
            if languagesCache.filter({ $0["code"] == language["code"] }).isEmpty {
                languagesCache.append(language)
                
                promises.append({
                    return self.createLanguage(code: language["code"] ?? "NULL",
                                               displayCode: language["display_code"] ?? "NULL",
                                               name: language["name"] ?? "NULL")
                })
            }
        }
        
        if let watermark = dict["watermark"] as? String {
            if !watermarksCache.contains(watermark) {
                watermarksCache.append(watermark)
                
                promises.append({
                    return self.create(watermark: watermark)
                })
            }
        }
        
        if let layout = filterLayout(dict: dict) {
            if layoutsCache.filter({ $0["name"] == layout["name"] }).isEmpty {
                layoutsCache.append(layout)
                
                promises.append({
                    return self.createLayout(name: layout["name"] ?? "NULL",
                                             description_: layout["description_"] ?? "NULL")
                })
            }
        }
        
        if let frame = filterFrame(dict: dict) {
            if framesCache.filter({ $0["name"] == frame["name"] }).isEmpty {
                framesCache.append(frame)
                
                promises.append({
                    return self.createFrame(name: frame["name"] ?? "NULL",
                                            description_: frame["description_"] ?? "NULL")
                })
            }
        }
        
        for frameEffect in filterFrameEffects(dict: dict) {
            if frameEffectsCache.filter({ $0["id"] == frameEffect["id"] }).isEmpty {
                frameEffectsCache.append(frameEffect)
                
                promises.append({
                    return self.createFrameEffect(id: frameEffect["id"] ?? "NULL",
                                                  name: frameEffect["name"] ?? "NULL",
                                                  description_: frameEffect["description_"] ?? "NULL")
                })
            }
        }
        
        for color in filterColors(dict: dict) {
            if colorsCache.filter({ $0["name"] as? String ?? "NULL" == color["name"] as? String ?? "NULL" }).isEmpty {
                colorsCache.append(color)
                
                promises.append({
                    return self.createColor(symbol: color["symbol"] as? String ?? "NULL",
                                            name: color["name"] as? String ?? "NULL",
                                            isManaColor: color["is_mana_color"] as? Bool ?? false)
                })
            }
        }
        
        if let dictLegalities = dict["legalities"] as? [String: String] {
            for key in dictLegalities.keys {
                if !formatsCache.contains(key) {
                    formatsCache.append(key)
                    
                    promises.append({
                        return self.create(format: key)
                    })
                }
            }
            for value in dictLegalities.values {
                if !legalitiesCache.contains(value) {
                    legalitiesCache.append(value)
                    
                    promises.append({
                        return self.create(legality: value)
                    })
                }
            }
        }
        
        for type in filterTypes(dict: dict) {
            if typesCache.filter({ $0["name"] as? String ?? "NULL" == type["name"] as? String ?? "NULL" }).isEmpty {
                typesCache.append(type)
                
                promises.append(({
                    return self.createCardType(name: type["name"] as? String ?? "NULL",
                                               parent: type["parent"] as? String ?? "NULL")
                }))
            }
        }
        
        for component in filterComponents(dict: dict) {
            if !componentsCache.contains(component) {
                componentsCache.append(component)
                
                promises.append({
                    return self.create(component: component)
                })
            }
        }
        
        promises.append({
            return self.create(card: dict)
        })
        
        if let parts = self.filterParts(dict: dict) {
            for part in parts {
                promises.append({
                    return self.createPart(card: part["cmcard"] as? String ?? "NULL",
                                           component: part["cmcomponent"] as? String ?? "NULL",
                                           cardPart: part["cmcard_part"] as? String ?? "NULL")
                })
            }
        }
        
        if let faces = self.filterFaces(dict: dict) {
            for face in faces {
                promises.append({
                    return self.create(card: face)
                })
                
                if let card = face["cmcard"] as? String,
                   let cardFace = face["new_id"] as? String {
                    promises.append({
                        return self.createFace(card: card,
                                               cardFace: cardFace)
                    })
                }
            }
        }
        
        return promises
    }
    
    func readCardDataLines(completion: ([String: Any]) -> Void) {
        let cardsPath = "\(cachePath)/\(cardsRemotePath.components(separatedBy: "/").last ?? "")"
        let fileReader = StreamingFileReader(path: cardsPath)
        
        while let line = fileReader.readLine() {
            var cleanLine = String(line)
            
            if cleanLine.hasSuffix("}},") {
                cleanLine.removeLast()
            }
            
            guard cleanLine.hasPrefix("{\""),
                let data = cleanLine.data(using: .utf16),
                let dict = try! JSONSerialization.jsonObject(with: data,
                                                             options: .mutableContainers) as? [String: Any] else {
                continue
            }
                    
            completion(dict)
        }
    }
    
    func readCardData(fileReader: StreamingFileReader, lines: Int) -> [[String: Any]] {
        var array = [[String: Any]]()
        
        while let line = fileReader.readLine() {
            var cleanLine = String(line)
            
            if cleanLine.hasSuffix("}},") {
                cleanLine.removeLast()
            }
            
            guard cleanLine.hasPrefix("{\""),
                let data = cleanLine.data(using: .utf16),
                let dict = try! JSONSerialization.jsonObject(with: data,
                                                             options: .mutableContainers) as? [String: Any] else {
                continue
            }
            
            array.append(dict)
            
            if array.count == lines {
                break
            }
        }
        
        return array
    }
    
    func filterLanguage(dict: [String: Any]) -> [String: String]? {
        guard let lang = dict["lang"] as? String else {
            return nil
        }
            
        let code = lang
        var displayCode = "NULL"
        var name = "NULL"
        var nameSection = "NULL"
        
        switch code {
        case "en":
            displayCode = "EN"
            name = "English"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "es":
            displayCode = "ES"
            name = "Spanish"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "fr":
            displayCode = "FR"
            name = "French"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "de":
            displayCode = "DE"
            name = "German"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "it":
            displayCode = "IT"
            name = "Italian"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "pt":
            displayCode = "PT"
            name = "Portuguese"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ja":
            displayCode = "JP"
            name = "Japanese"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ko":
            displayCode = "KR"
            name = "Korean"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ru":
            displayCode = "RU"
            name = "Russian"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "zhs":
            displayCode = "CS"
            name = "Simplified Chinese"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "zht":
            displayCode = "CT"
            name = "Traditional Chinese"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "he":
            name = "Hebrew"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "la":
            name = "Latin"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "grc":
            name = "Ancient Greek"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ar":
            name = "Arabic"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "sa":
            name = "Sanskrit"
            nameSection = sectionFor(name: name) ?? "NULL"
        case "ph":
            name = "Phyrexian"
            nameSection = sectionFor(name: name) ?? "NULL"
        default:
            ()
        }
        
        return [
            "code": code,
            "display_code": displayCode,
            "name": name,
            "name_section": nameSection
        ]
    }
    
    func filterLayout(dict: [String: Any]) -> [String: String]? {
        guard let layout = dict["layout"] as? String else {
            return nil
        }
        
        let name = layout
        var description_ = "NULL"
        
        switch name {
        case "normal":
            description_ = "A standard Magic card with one face"
        case "split":
            description_ = "A split-faced card"
        case "flip":
            description_ = "Cards that invert vertically with the flip keyword"
        case "transform":
            description_ = "Double-sided cards that transform"
        case "modal_dfc":
            description_ = "Double-sided cards that can be played either-side"
        case "meld":
            description_ = "Cards with meld parts printed on the back"
        case "leveler":
            description_ = "Cards with Level Up"
        case "saga":
            description_ = "Saga-type cards"
        case "adventure":
            description_ = "Cards with an Adventure spell part"
        case "planar":
            description_ = "Plane and Phenomenon-type cards"
        case "scheme":
            description_ = "Scheme-type cards"
        case "vanguard":
            description_ = "Vanguard-type cards"
        case "token":
            description_ = "Token cards"
        case "double_faced_token":
            description_ = "Tokens with another token printed on the back"
        case "emblem":
            description_ = "Emblem cards"
        case "augment":
            description_ = "Cards with Augment"
        case "host":
            description_ = "Host-type cards"
        case "art_series":
            description_ = "Art Series collectable double-faced cards"
        case "double_sided":
            description_ = "A Magic card with two sides that are unrelated"
        default:
            ()
        }

        return [
            "name": name,
            "description_": description_
        ]
    }
    
    func filterFrame(dict: [String: Any]) -> [String: String]? {
        guard let frame = dict["frame"] as? String else {
            return nil
        }
        
        let name = frame
        var description_ = "NULL"
        
        switch name {
        case "1993":
            description_ = "The original Magic card frame, starting from Limited Edition Alpha."
        case "1997":
            description_ = "The updated classic frame starting from Mirage block."
        case "2003":
            description_ = "The \"modern\" Magic card frame, introduced in Eighth Edition and Mirrodin block."
        case "2015":
            description_ = "The holofoil-stamp Magic card frame, introduced in Magic 2015."
        case "future":
            description_ = "The frame used on cards from the future."
        default:
            ()
        }
        return [
            "name": name,
            "description_": description_
        ]
    }
    
    func filterFrameEffects(dict: [String: Any]) -> [[String: String]] {
        var array = [[String: String]]()
        
        guard let frameEffects = dict["frame_effects"] as? [String] else {
            return array
        }
        
        for frameEffect in frameEffects {
            let id = frameEffect
            var name = "NULL"
            var description_ = "NULL"
            
            switch id {
            case "legendary":
                name = capitalize(string: id)
                description_ = "The cards have a legendary crown"
            case "miracle":
                name = capitalize(string: id)
                description_ = "The miracle frame effect"
            case "nyxtouched":
                name = "Nyx-touched"
                description_ = "The Nyx-touched frame effect"
            case "draft":
                name = capitalize(string: id)
                description_ = "The draft-matters frame effect"
            case "devoid":
                name = capitalize(string: id)
                description_ = "The Devoid frame effect"
            case "tombstone":
                name = capitalize(string: id)
                description_ = "The Odyssey tombstone mark"
            case "colorshifted":
                name = capitalize(string: id)
                description_ = "A colorshifted frame"
            case "inverted":
                name = capitalize(string: id)
                description_ = "The FNM-style inverted frame"
            case "sunmoondfc":
                name = "Sun and Moon"
                description_ = "The sun and moon transform marks"
            case "compasslanddfc":
                name = "Compass and Land"
                description_ = "The compass and land transform marks"
            case "originpwdfc":
                name = "Origins and Planeswalkers"
                description_ = "The Origins and planeswalker transform marks"
            case "mooneldrazidfc":
                name = "Moon and Eldrazi"
                description_ = "The moon and Eldrazi transform marks"
            case "waxingandwaningmoondfc":
                name = "Waxing and Waning Crescent moon"
                description_ = "The waxing and waning crescent moon transform marks"
            case "showcase":
                name = capitalize(string: id)
                description_ = "A custom Showcase frame"
            case "extendedart":
                name = "Extended Art"
                description_ = "An extended art frame"
            case "companion":
                name = capitalize(string: id)
                description_ = "The cards have a companion frame"
            case "etched":
                name = capitalize(string: id)
                description_ = "The cards have an etched foil treatment"
            case "snow":
                name = capitalize(string: id)
                description_ = "The cards have the snowy frame effect"
            default:
                name = capitalize(string: id)
            }
        
            array.append([
                "id": id,
                "name": name,
                "description_": description_
            ])
        }
        
        return array
    }
    
    func filterColors(dict: [String: Any]) -> [[String: Any]] {
        var array = [[String: Any]]()
        
        guard let colors = dict["colors"] as? [String] else {
            return array
        }
        
        for color in colors {
            
            let symbol = color
            var name = "NULL"
            
            switch symbol {
            case "B":
                name = "Black"
            case "G":
                name = "Green"
            case "R":
                name = "Red"
            case "U":
                name = "Blue"
            case "W":
            name = "White"
            default:
                ()
            }
            array.append([
                "symbol": symbol,
                "name": name,
                "is_mana_color": true
            ])
        }
        
        return array
    }
    
    func filterTypes(dict: [String: Any]) -> [[String: Any]] {
        guard let typeLine = dict["type_line"] as? String else {
            return [[String: Any]]()
        }
        
        return extractTypesFrom(typeLine)
    }
    
    func filterComponents(dict: [String: Any]) -> [String] {
        var array = [String]()
        
        guard let parts = dict["all_parts"] as? [[String: Any]] else {
            return array
        }
        
        for part in parts {
            if let component = part["component"] as? String {
                array.append(component)
            }
        }
        
        return array
    }
    
    func filterParts(dict: [String: Any]) -> [[String: Any]]? {
        guard let parts = dict["all_parts"] as? [[String: Any]],
              let set = dict["set"] as? String,
              let language = dict["lang"] as? String,
              let collectorNumber = dict["collector_number"] as? String else {
            return nil
        }
        
        let newId = "\(set)_\(language)_\(collectorNumber.replacingOccurrences(of: "★", with: "star"))"
        var array = [[String: Any]]()
        
        for i in 0...parts.count-1 {
            let part = parts[i]
            
            if let partId = part["id"] as? String,
                let component = part["component"] as? String {
                array.append(["cmcard": newId,
                              "cmcomponent": component,
                              "cmcard_part": partId])
            }
        }
        
        return array
    }
    
    func filterFaces(dict: [String: Any]) -> [[String: Any]]? {
        guard let faces = dict["card_faces"] as? [[String: Any]],
              let set = dict["set"] as? String,
              let language = dict["lang"] as? String,
              let collectorNumber = dict["collector_number"] as? String else {
            return nil
        }
        
        let newId = "\(set)_\(language)_\(collectorNumber.replacingOccurrences(of: "★", with: "star"))"
        var array = [[String: Any]]()
        
        
        for i in 0...faces.count-1 {
            let face = faces[i]
            let faceId = "\(newId)_\(i)"
            var newFace = [String: Any]()
            
            for (k,v) in face {
                if k == "image_uris" {
                    continue
                }
                newFace[k] = v
            }
            newFace["face_order"] = i
            newFace["new_id"] = faceId
            newFace["cmcard"] = newId
            
            array.append(newFace)
        }
        
        return array
    }
    
    private func extractTypesFrom(_ typeLine: String) -> [[String: String]]  {
        var filteredTypes = [[String: String]]()
        let emdash = "\u{2014}"
        var types = Set<String>()
        
        if typeLine.contains("//") {
            for type in typeLine.components(separatedBy: "//") {
                let s = type.components(separatedBy: emdash)
                
                if let first = s.first,
                    let last = s.last {
                    
                    for f in first.components(separatedBy: " ") {
                        if !f.isEmpty && f != emdash {
                            let trimmed = f.trimmingCharacters(in: .whitespacesAndNewlines)
                            types.insert(trimmed)
                        }
                    }
                    
                    let trimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
                    types.insert(trimmed)
                }
            }
        } else if typeLine.contains(emdash) {
            let s = typeLine.components(separatedBy: emdash)
            
            if let first = s.first,
                let last = s.last {
                
                for f in first.components(separatedBy: " ") {
                    if !f.isEmpty && f != emdash {
                        let trimmed = f.trimmingCharacters(in: .whitespacesAndNewlines)
                        types.insert(trimmed)
                    }
                }
                
                let trimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
                types.insert(trimmed)
            }
        } else {
            types.insert(typeLine)
        }
        
        let arrayTypes = types.reversed()
        for i in 0...arrayTypes.count-1 {
            let type = arrayTypes[i]
            var parent = "NULL"
            var isFound = false
            
            if type.isEmpty {
                continue
            }
            for filteredType in filteredTypes {
                if let name = filteredType["name"] {
                    isFound = name == type
                }
            }
            if !isFound {
                if i+1 <= types.count-1 {
                    parent = arrayTypes[i+1]
                }
                
                filteredTypes.append([
                    "name": type,
                    "parent": parent
                ])
            }
        }
        
        return filteredTypes
    }
    
    func extractSupertypesFrom(_ typeLine: String) -> Set<String>  {
        let emdash = "\u{2014}"
        var types = Set<String>()
        
        if typeLine.contains("//") {
            for type in typeLine.components(separatedBy: "//") {
                let s = type.components(separatedBy: emdash)
                
                if let first = s.first {
                    for f in first.components(separatedBy: " ") {
                        if !f.isEmpty && f != emdash {
                            let trimmed = f.trimmingCharacters(in: .whitespacesAndNewlines)
                            types.insert(trimmed)
                        }
                    }
                }
            }
        } else if typeLine.contains(emdash) {
            let s = typeLine.components(separatedBy: emdash)
            
            if let first = s.first {
                for f in first.components(separatedBy: " ") {
                    if !f.isEmpty && f != emdash {
                        let trimmed = f.trimmingCharacters(in: .whitespacesAndNewlines)
                        types.insert(trimmed)
                    }
                }
            }
        } else {
            types.insert(typeLine)
        }
        
        return types
    }
    
    func extractSubtypesFrom(_ typeLine: String) -> Set<String>  {
        let emdash = "\u{2014}"
        var types = Set<String>()
        
        if typeLine.contains("//") {
            for type in typeLine.components(separatedBy: "//") {
                let s = type.components(separatedBy: emdash)
                
                if let last = s.last {
                    let trimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
                    types.insert(trimmed)
                }
            }
        } else if typeLine.contains(emdash) {
            let s = typeLine.components(separatedBy: emdash)
            
            if let last = s.last {
                let trimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
                types.insert(trimmed)
            }
        } else {
            types.insert(typeLine)
        }
        
        return types
    }
    
//
//    func updateCards3() -> Promise<Void> {
//        return Promise { seal in
//            let sortDescriptors = [SortDescriptor(keyPath: "set.releaseDate", ascending: true),
//                                   SortDescriptor(keyPath: "name", ascending: true)]
//            let cards = realm.objects(CMCard.self).filter("id != nil").sorted(by: sortDescriptors)
//            var count = 0
//            print("Updating cards3: \(count)/\(cards.count) \(Date())")
//
//            // reload the date
//            cachedCardTypes.removeAll()
//            for object in realm.objects(CMCardType.self) {
//                cachedCardTypes.append(object)
//            }
//
//            // update the cards
//            try! realm.write {
//                for card in cards {
//                    // myType
//                    if let typeLine = card.typeLine,
//                        let name = typeLine.name {
//
//                        var types = [String]()
//                        for type in CardType.allCases {
//                            for n in name.components(separatedBy: " ") {
//                                let desc = type.description
//                                if n == desc && !types.contains(desc) {
//                                    types.append(desc)
//                                }
//                            }
//                        }
//
//                        if types.count == 1 {
//                            card.myType = findCardType(with: types.first!,
//                                                       language: enLanguage!)
//                        } else if types.count > 1 {
//                            card.myType = findCardType(with: "Multiple",
//                                                       language: enLanguage!)
//                        }
//                    }
//
//                    // Firebase id = set.code + _ + card.name + _ + number? + _ + languageCode
//                    if let _ = card.id,
//                        let set = card.set,
//                        let setCode = set.code,
//                        let language = card.language,
//                        let languageCode = language.code,
//                        let name = card.name {
//                        var firebaseID = "\(setCode.uppercased())_\(name)"
//
//                        let variations = realm.objects(CMCard.self).filter("set.code = %@ AND language.code = %@ AND name = %@",
//                                                                           setCode,
//                                                                           languageCode,
//                                                                           name)
//
//                        if variations.count > 1 {
//                            let orderedVariations = variations.sorted(by: {(a, b) -> Bool in
//                                return a.myNumberOrder < b.myNumberOrder
//                            })
//                            var index = 1
//
//                            for c in orderedVariations {
//                                if c.id == card.id {
//                                    firebaseID += "_\(index)"
//                                    break
//                                } else {
//                                    index += 1
//                                }
//                            }
//                        }
//
//                        // add language code for non-english cards
//                        if languageCode != "en" {
//                            firebaseID += "_\(languageCode)"
//                        }
//
//                        card.firebaseID = ManaKit.sharedInstance.encodeFirebase(key: firebaseID)
//                    }
//
//                    realm.add(card)
//
//                    count += 1
//                    if count % printMilestone == 0 {
//                        print("Updating cards3: \(count)/\(cards.count) \(Date())")
//                    }
//                }
//
//                seal.fulfill(())
//            }
//        }
//    }
}
