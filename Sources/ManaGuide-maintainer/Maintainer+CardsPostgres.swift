//
//  Maintainer+CardsPostgres.swift
//  ManaKit_Example
//
//  Created by Vito Royeca on 10/27/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import PostgresClientKit
import PromiseKit

extension Maintainer {
    func processOtherCardsData() -> Promise<Void> {
        return Promise { seal in
            let label = "processOtherCardsData"
            let date = self.startActivity(label: label)
            let promises = [createOtherLanguagesPromise(),
                            createOtherPrintingsPromise(),
                            createVariationsPromise()]
            
            firstly {
                when(fulfilled: promises)
            }.done {
                self.endActivity(label: label, from: date)
                seal.fulfill(())
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func create(artist: String) -> Promise<Void> {
        let names = artist.components(separatedBy: " ")
        var firstName = ""
        var lastName = ""
        var nameSection = ""
        
        if names.count > 1 {
            if let last = names.last {
                lastName = last
                nameSection = lastName
            }
            
            for i in 0...names.count - 2 {
                firstName.append("\(names[i])")
                if i != names.count - 2 && names.count >= 3 {
                    firstName.append(" ")
                }
            }
            
        } else {
            firstName = names.first ?? "NULL"
            nameSection = firstName
        }
        nameSection = sectionFor(name: nameSection) ?? "NULL"
        
        let query = "SELECT createOrUpdateArtist($1,$2,$3,$4)"
        let parameters = [artist,
                          firstName,
                          lastName,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func create(rarity: String) -> Promise<Void> {
        let capName = capitalize(string: displayFor(name: rarity))
        let nameSection = sectionFor(name: rarity) ?? "NULL"
        
        let query = "SELECT createOrUpdateRarity($1,$2)"
        let parameters = [capName,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func createLanguage(code: String, displayCode: String, name: String) -> Promise<Void> {
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateLanguage($1,$2,$3,$4)"
        let parameters = [code,
                          displayCode,
                          name,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func createLayout(name: String, description_: String) -> Promise<Void> {
        let capName = capitalize(string: displayFor(name: name))
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateLayout($1,$2,$3)"
        let parameters = [capName,
                          nameSection,
                          description_]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func create(watermark: String) -> Promise<Void> {
        let capName = capitalize(string: displayFor(name: watermark))
        let nameSection = sectionFor(name: watermark) ?? "NULL"
        
        let query = "SELECT createOrUpdateWatermark($1,$2)"
        let parameters = [capName,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func createFrame(name: String, description_: String) -> Promise<Void> {
        let capName = capitalize(string: displayFor(name: name))
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateFrame($1,$2,$3)"
        let parameters = [capName,
                          nameSection,
                          description_]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func createFrameEffect(id: String, name: String, description_: String) -> Promise<Void> {
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateFrameEffect($1,$2,$3,$4)"
        let parameters = [id,
                          name,
                          nameSection,
                          description_]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func createColor(symbol: String, name: String, isManaColor: Bool) -> Promise<Void> {
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateColor($1,$2,$3,$4)"
        let parameters = [symbol,
                          name,
                          nameSection,
                          isManaColor] as [Any]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func create(format: String) -> Promise<Void> {
        let capName = capitalize(string: displayFor(name: format))
        let nameSection = sectionFor(name: format) ?? "NULL"
        
        let query = "SELECT createOrUpdateFormat($1,$2)"
        let parameters = [capName,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func create(legality: String) -> Promise<Void> {
        let capName = capitalize(string: displayFor(name: legality))
        let nameSection = sectionFor(name: legality) ?? "NULL"
        
        let query = "SELECT createOrUpdateLegality($1,$2)"
        let parameters = [capName,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func createCardType(name: String, parent: String) -> Promise<Void> {
        let nameSection = sectionFor(name: name) ?? "NULL"
        
        let query = "SELECT createOrUpdateCardType($1,$2,$3)"
        let parameters = [name,
                          nameSection,
                          parent]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func create(component: String) -> Promise<Void> {
        let capName = capitalize(string: displayFor(name: component))
        let nameSection = sectionFor(name: component) ?? "NULL"
        
        let query = "SELECT createOrUpdateComponent($1,$2)"
        let parameters = [capName,
                          nameSection]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
//    func createDeleteFaces() -> Promise<Void> {
//        let query = "DELETE FROM cmcard_face"
//        return createPromise(with: query,
//                             parameters: nil)
//    }
    
    func createFace(card: String, cardFace: String) -> Promise<Void> {
        let query = "SELECT createOrUpdateCardFaces($1,$2)"
        let parameters = [card,
                          cardFace]
        return createPromise(with: query,
                             parameters: parameters)
    }
    
//    func createDeleteParts() -> Promise<Void> {
//        let query = "DELETE FROM cmcard_component_part"
//        return createPromise(with: query,
//                             parameters: nil)
//    }
    
    func createPart(card: String, component: String, cardPart: String) -> Promise<Void> {
        let capName = capitalize(string: displayFor(name: component))
        
        let query = "SELECT createOrUpdateCardParts($1,$2,$3)"
        let parameters = [card,
                          capName,
                          cardPart]
        return createPromise(with: query,
                             parameters: parameters)
    }

    func createOtherLanguagesPromise() -> Promise<Void> {
        let parameters = [singleCardNewID ?? "NULL"]
        return createPromise(with: "select createOrUpdateCardOtherLanguages($1)",
                             parameters: parameters)
    }

    func createOtherPrintingsPromise() -> Promise<Void> {
        let parameters = [singleCardNewID ?? "NULL"]
        return createPromise(with: "select createOrUpdateCardOtherPrintings($1)",
                             parameters: parameters)
    }
    
    func createVariationsPromise() -> Promise<Void> {
        let parameters = [singleCardNewID ?? "NULL"]
        return createPromise(with: "select createOrUpdateCardVariations($1)",
                             parameters: parameters)
    }
    
    func create(card: [String: Any]) -> Promise<Void> {
        let collectorNumber = card["collector_number"] as? String ?? "NULL"
        let cmc = card["cmc"] as? Double ?? Double(0)
        let flavorText = card["flavor_text"] as? String ?? "NULL"
        let isFoil = card["foil"] as? Bool ?? false
        let isFullArt = card["full_art"] as? Bool ?? false
        let isHighresImage = card["highres_image"] as? Bool ?? false
        let isNonfoil = card["nonfoil"] as? Bool ?? false
        let isOversized = card["oversized"] as? Bool ?? false
        let isReserved = card["reserved"] as? Bool ?? false
        let isStorySpotlight = card["story_spotlight"] as? Bool ?? false
        let loyalty = card["loyalty"] as? String ?? "NULL"
        let manaCost = card["mana_cost"] as? String ?? "NULL"
        
        var multiverseIds = "{}"
        if let a = card["multiverse_ids"] as? [Int],
            !a.isEmpty {
            multiverseIds = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var myNameSection = "NULL"
        if let name = card["name"] as? String {
            myNameSection = sectionFor(name: name) ?? "NULL"
        }
        
        var myNumberOrder = Double(0)
        if collectorNumber != "NULL" {
            myNumberOrder = order(of: collectorNumber)
        }
        
        let name = card["name"] as? String ?? "NULL"
        let oracleText = card["oracle_text"] as? String ?? "NULL"
        let power = card["power"] as? String ?? "NULL"
        let printedName = card["printed_name"] as? String ?? "NULL"
        let printedText = card["printed_text"] as? String ?? "NULL"
        let toughness = card["toughness"] as? String ?? "NULL"
        let arenaId = card["arena_id"] as? String ?? "NULL"
        let mtgoId = card["mtgo_id"] as? String ?? "NULL"
        let tcgplayerId = card["tcgplayer_id"] as? Int ?? Int(0)
        let handModifier = card["hand_modifier"] as? String ?? "NULL"
        let lifeModifier = card["life_modifier"] as? String ?? "NULL"
        let isBooster = card["booster"] as? Bool ?? false
        let isDigital = card["digital"] as? Bool ?? false
        let isPromo = card["promo"] as? Bool ?? false
        let releasedAt = card["released_at"] as? String ?? "NULL"
        let isTextless = card["textless"] as? Bool ?? false
        let mtgoFoilId = card["mtgo_foil_id"] as? String ?? "NULL"
        let isReprint = card["reprint"] as? Bool ?? false
        let artist = card["artist"] as? String ?? "NULL"
        let set = card["set"] as? String ?? "NULL"
        let rarity = capitalize(string: card["rarity"] as? String ?? "NULL")
        let language = card["lang"] as? String ?? "NULL"
        let layout = capitalize(string: displayFor(name: card["layout"] as? String ?? "NULL"))
        let watermark = capitalize(string: card["watermark"] as? String ?? "NULL")
        let frame = capitalize(string: card["frame"] as? String ?? "NULL")
        
        var frameEffects = "{}"
        if let a = card["frame_effects"] as? [String],
            !a.isEmpty {
            frameEffects = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var colors = "{}"
        if let a = card["colors"] as? [String],
            !a.isEmpty {
            colors = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var colorIdentities = "{}"
        if let a = card["color_identity"] as? [String],
            !a.isEmpty {
            colorIdentities = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var colorIndicators = "{}"
        if let a = card["color_indicator"] as? [String],
            !a.isEmpty {
            colorIndicators = "\(a)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var legalities = "{}"
        if let legalitiesDict = card["legalities"] as? [String: String] {
            var newLegalities = [String: String]()
            for (k,v) in legalitiesDict {
                newLegalities[capitalize(string: displayFor(name: k))] = capitalize(string: displayFor(name: v))
            }
            legalities = "\(newLegalities)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        let typeLine = card["type_line"] as? String ?? "NULL"
        let printedTypeLine = card["printed_type_line"] as? String ?? "NULL"
        
        var cardtypeSubtypes = "{}"
        if let tl = card["type_line"] as? String {
            let subtypes = extractSubtypesFrom(tl)
            cardtypeSubtypes = "\(subtypes)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        var cardtypeSupertypes = "{}"
        if let tl = card["type_line"] as? String {
            let supertypes = extractSupertypesFrom(tl)
            cardtypeSupertypes = "\(supertypes)"
                .replacingOccurrences(of: "[", with: "{")
                .replacingOccurrences(of: "]", with: "}")
        }
        
        let faceOrder = card["face_order"] as? Int ?? Int(0)
        let newId = card["new_id"] as? String ?? "\(set)_\(language)_\(collectorNumber.replacingOccurrences(of: "★", with: "star"))"
        let oracle_id = card["oracle_id"] as? String ?? "NULL"
        let id = card["id"] as? String ?? "NULL"
        
        // unhandled...
        // border_color
        // games
        // promo_types
        // preview.previewed_at
        // preview.source_uri
        // preview.source
        let query = "SELECT createOrUpdateCard($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$50,$51,$52,$53)"
        let parameters = [collectorNumber,
                          cmc,
                          flavorText,
                          isFoil,
                          isFullArt,
                          isHighresImage,
                          isNonfoil,
                          isOversized,
                          isReserved,
                          isStorySpotlight,
                          loyalty,
                          manaCost,
                          multiverseIds,
                          myNameSection,
                          myNumberOrder,
                          name,
                          oracleText,
                          power,
                          printedName,
                          printedText,
                          toughness,
                          arenaId,
                          mtgoId,
                          tcgplayerId,
                          handModifier,
                          lifeModifier,
                          isBooster,
                          isDigital,
                          isPromo,
                          releasedAt,
                          isTextless,
                          mtgoFoilId,
                          isReprint,
                          artist,
                          set,
                          rarity,
                          language,
                          layout,
                          watermark,
                          frame,
                          frameEffects,
                          colors,
                          colorIdentities,
                          colorIndicators,
                          legalities,
                          typeLine,
                          printedTypeLine,
                          cardtypeSubtypes,
                          cardtypeSupertypes,
                          faceOrder,
                          newId,
                          oracle_id,
                          id] as [Any]
        return createPromise(with: query,
                             parameters: parameters)
    }
}
