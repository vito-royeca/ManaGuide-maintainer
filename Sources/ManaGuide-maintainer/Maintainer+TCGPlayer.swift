//
//  Maintainer+TCGPlayer.swift
//  ManaKit_Example
//
//  Created by Jovito Royeca on 23/10/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import PostgresClientKit
import PromiseKit
import PMKFoundation

extension Maintainer {
    func processPricingData() -> Promise<Void> {
        return Promise { seal in
            let label = "processPricingData"
            let date = self.startActivity(label: label)
            
            firstly {
//                self.createStorePromise(name: self.storeName)
                self.getTcgPlayerToken()
            }.then {
                self.fetchSets()
            }.then { groupIds in
                self.fetchTcgPlayerCardPricing(groupIds: groupIds)
            }.done { promises in
                let completion = {
                    self.endActivity(label: label, from: date)
                    seal.fulfill(())
                }
                self.execInSequence(label: label,
                                    promises: promises,
                                    completion: completion)
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    func getTcgPlayerToken() -> Promise<Void> {
        return Promise { seal  in
            guard let urlString = "https://api.tcgplayer.com/token".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                let url = URL(string: urlString) else {
                fatalError("Malformed url")
            }
            
            let query = "grant_type=client_credentials&client_id=\(TCGPlayer.publicKey)&client_secret=\(TCGPlayer.privateKey)"
            
            var rq = URLRequest(url: url)
            rq.httpMethod = "POST"
            rq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            rq.httpBody = query.data(using: .utf8)
            
            firstly {
                URLSession.shared.dataTask(.promise, with: rq)
            }.compactMap {
                try JSONSerialization.jsonObject(with: $0.data) as? [String: Any]
            }.done { json in
                guard let token = json["access_token"] as? String else {
                    fatalError("access_token is nil")
                }
                
                self.tcgplayerAPIToken = token
                seal.fulfill(())
            }.catch { error in
                print("\(error)")
                seal.reject(error)
            }
        }
    }
    
    func fetchSets() -> Promise<[Int32]> {
        return Promise { seal in
            firstly {
                createNodePromise(apiPath: "/sets?json=true",
                                  httpMethod: "GET",
                                  httpBody: nil)
            }.compactMap { (data, result) in
                try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            }.done { data in
                var tcgPlayerIds = [Int32]()

                for d in data {
                    for (k,v) in d {
                        if k == "tcgplayer_id" {
                            if let tcgPlayerId = v as? Int32 {
                                if tcgPlayerId > 0 {
                                    tcgPlayerIds.append(tcgPlayerId)
                                }    
                            }
                        }
                    }
                }

                seal.fulfill(tcgPlayerIds)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func createNodePromise(apiPath: String, httpMethod: String, httpBody: String?) -> Promise<(data: Data, response: URLResponse)> {
        // TODO: remove hardcoded url
        let urlString = "http://managuideapp.com\(apiPath)"
        
        guard let cleanURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: cleanURL) else {
            fatalError("Malformed url")
        }
        
        var rq = URLRequest(url: url)
        rq.httpMethod = httpMethod.uppercased()
        rq.setValue("application/json", forHTTPHeaderField: "Accept")
        if let httpBody = httpBody {
            rq.httpBody = httpBody.replacingOccurrences(of: "\n", with: "").data(using: .utf8)
        }
    
        return URLSession.shared.dataTask(.promise, with: rq)
    }
    
//    func createStorePromise(name: String) -> Promise<Void> {
//        let nameSection = self.sectionFor(name: name) ?? "NULL"
//
//        let query = "SELECT createOrUpdateStore($1,$2)"
//        let parameters = [name,
//                          nameSection]
//        return createPromise(with: query,
//                             parameters: parameters)
//    }
    
    func fetchTcgPlayerCardPricing(groupIds: [Int32]) -> Promise<[()->Promise<Void>]> {
        return Promise { seal in
            var array = [Promise<[()->Promise<Void>]>]()
            var promises = [()->Promise<Void>]()
            
            for groupId in groupIds {
                array.append(fetchCardPricingBy(groupId: groupId))
            }
            
            firstly {
                when(fulfilled: array)
            }.done { results in
                for result in results {
                    promises.append(contentsOf: result)
                }
                seal.fulfill(promises)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func fetchCardPricingBy(groupId: Int32) -> Promise<[()->Promise<Void>]> {
        return Promise { seal in
            guard let urlString = "https://api.tcgplayer.com/\(TCGPlayer.apiVersion)/pricing/group/\(groupId)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                let url = URL(string: urlString) else {
                fatalError("Malformed url")
            }
            
            var rq = URLRequest(url: url)
            rq.httpMethod = "GET"
            rq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            rq.setValue("Bearer \(tcgplayerAPIToken)", forHTTPHeaderField: "Authorization")
            
            firstly {
                URLSession.shared.dataTask(.promise, with:rq)
            }.compactMap {
                try JSONSerialization.jsonObject(with: $0.data) as? [String: Any]
            }.done { json in
                guard let results = json["results"] as? [[String: Any]] else {
                    fatalError("results is nil")
                }
                var promises = [()->Promise<Void>]()
                
                for result in results {
                    promises.append({
                        return self.createCardPricingPromise(price: result)
                    })
                }
                seal.fulfill(promises)
                
            }.catch { error in
                print(error)
                seal.reject(error)
            }
        }
    }
    
    func createCardPricingPromise(price: [String: Any]) -> Promise<Void> {
        let low = price["lowPrice"] as? Double ?? 0.0
        let median = price["midPrice"] as? Double ?? 0.0
        let high = price["highPrice"] as? Double ?? 0.0
        let market = price["marketPrice"] as? Double ?? 0.0
        let directLow = price["directLowPrice"] as? Double ?? 0.0
        let tcgPlayerId = price["productId"]  as? Int ?? 0
        let isFoil = price["subTypeName"] as? String ?? "Foil" == "Foil" ? true : false
        
        let query = "SELECT createOrUpdateCardPrice($1,$2,$3,$4,$5,$6,$7)"
        let parameters = [
            low,
            median,
            high,
            market,
            directLow,
            tcgPlayerId,
            isFoil
            ] as [Any]
        
        return createPromise(with: query,
                             parameters: parameters)
    }
}
