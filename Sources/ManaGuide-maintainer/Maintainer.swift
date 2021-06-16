//
//  Maintainer.swift
//  ManaKit_Example
//
//  Created by Jovito Royeca on 23/10/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import TSCBasic
import TSCUtility
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import PostgresClientKit
import PromiseKit
import PMKFoundation

class Maintainer {
    // MARK: - Constants
    let printMilestone    = 1000
    let bulkDataFileName  = "scryfall-bulkData.json"
    let setsFileName      = "scryfall-sets.json"
    let keyruneFileName   = "keyrune.html"
    let rulesFileName     = "MagicCompRules.txt"
//    let setCodesForProcessing:[String]? = nil
    let storeName = "TCGPlayer"
    let cachePath = "/tmp"
    
    // MARK: - Variables
    var tcgplayerAPIToken = ""
    
    // remote file names
    let bulkDataRemotePath = "https://api.scryfall.com/bulk-data"
    var cardsRemotePath    = ""
    var rulingsRemotePath  = ""
    let setsRemotePath     = "https://api.scryfall.com/sets"
    let keyruneRemotePath  = "https://keyrune.andrewgioia.com/cheatsheet.html"
    let rulesRemotePath    = "https://media.wizards.com/2021/downloads/MagicCompRules 20210419.txt"
    
    // local file names
    var bulkDataLocalPath  = ""
    var cardsLocalPath     = ""
    var rulingsLocalPath   = ""
    var setsLocalPath      = ""
    var keyruneLocalPath   = ""
    var rulesLocalPath     = ""
    
    var _bulkArray: [[String: Any]]?
    var bulkArray: [[String: Any]] {
        get {
            if _bulkArray == nil {
                _bulkArray = self.bulkData()
            }
            return _bulkArray!
        }
    }
    
    var _setsArray: [[String: Any]]?
    var setsArray: [[String: Any]] {
        get {
            if _setsArray == nil {
                _setsArray = self.setsData()
            }
            return _setsArray!
        }
    }
    
//    var _cardsArray: [[String: Any]]?
//    var cardsArray: [[String: Any]] {
//        get {
//            if _cardsArray == nil {
//                _cardsArray = [[String: Any]]()
//
//                for dict in self.cardsData() {
//                    var newDict = [String: Any]()
//
//                    for (k,v) in dict {
//                        newDict[k] = v
//                    }
//
//                    if let set = dict["set"] as? String,
//                       let language = dict["lang"] as? String,
//                       let collectorNumber = dict["collector_number"] as? String {
//                        let newId = "\(set)_\(language)_\(collectorNumber.replacingOccurrences(of: "★", with: "star"))"
//                        newDict["new_id"] = newId
//                    }
//                    _cardsArray!.append(newDict)
//                }
//
//            }
//            return _cardsArray!
//        }
//    }
    
    var _rulingsArray: [[String: Any]]?
    var rulingsArray: [[String: Any]] {
        get {
            if _rulingsArray == nil {
                _rulingsArray = self.rulingsData()
            }
            return _rulingsArray!
        }
    }
    
    var _rulesArray: [String]?
    var rulesArray: [String] {
        get {
            if _rulesArray == nil {
                _rulesArray = self.rulesData()
            }
            return _rulesArray!
        }
    }
    
    var _connection: Connection?
    var connection: Connection {
        get {
            if _connection == nil {
                _connection = self.createConnection()
            }
            return _connection!
        }
    }
    
    // MARK: - Database methods
    func checkServerInfo() {
        /*let viewModel = ServerInfoViewModel()
        
        firstly {
            viewModel.fetchRemoteData()
        }.compactMap { (data, result) in
            try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        }.then { data in
            viewModel.saveLocalData(data: data)
        }.then {
            viewModel.fetchLocalData()
        }.done {
//            if let serverInfo = viewModel.allObjects()?.first as? MGServerInfo {
//                if serverInfo.scryfallVersion != ManaKit.Constants.ScryfallDate {
//                    viewModel.deleteAllCache()
//                    self.updateDatabase()
//                }
//            } else {
                viewModel.deleteAllCache()
                self.updateDatabase()
//            }
        }.catch { error in
            print(error)
        }*/
        self.updateDatabase()
    }

    func createConnection() -> Connection {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = "192.168.1.182"
        configuration.port = 5432
        configuration.database = "managuide_prod"
        configuration.user = "managuide"
        configuration.credential = .cleartextPassword(password: "DarkC0nfidant")
        configuration.ssl = false
        
        do {
            let connection = try PostgresClientKit.Connection(configuration: configuration)
        
            return connection
        } catch {
            fatalError("\(error)")
        }
    }
    
    private func updateDatabase() {
        let label = "Managuide Maintainer"
        let dateStart = startActivity(label: label)
        
        bulkDataLocalPath = "\(cachePath)/\(ManaKit.Constants.ScryfallDate)_\(bulkDataFileName)"
        setsLocalPath     = "\(cachePath)/\(ManaKit.Constants.ScryfallDate)_\(setsFileName)"
        keyruneLocalPath  = "\(cachePath)/\(ManaKit.Constants.ScryfallDate)_\(keyruneFileName)"
        rulesLocalPath    = "\(cachePath)/\(ManaKit.Constants.ScryfallDate)_\(rulesFileName)"
        
        firstly {
            fetchData(from: bulkDataRemotePath, saveTo: bulkDataLocalPath)
        }.then {
            self.createBulkData()
        }.then {
            self.fetchData(from: self.setsRemotePath, saveTo: self.setsLocalPath)
        }.then {
            self.fetchData(from: self.keyruneRemotePath, saveTo: self.keyruneLocalPath)
        }.then {
            self.fetchData(from: self.cardsRemotePath, saveTo: self.cardsLocalPath)
        }.then {
            self.fetchData(from: self.rulingsRemotePath, saveTo: self.rulingsLocalPath)
        }.then {
            self.fetchData(from: self.rulesRemotePath, saveTo: self.rulesLocalPath)
        }/*.then {
            self.fetchCardImages()
        }.then {
            self.processSetsData()
        }*/.then {
            self.processCardsData()
        }/*.then {
            self.processRulingsData()
        }.then {
            self.processRulesData()
        }.then {
            self.processOtherCardsData()
        }.then {
            self.processPricingData()
        }.then {
            self.processScryfallPromise()
        }*/.done {
//            do {
//                try FileManager.default.removeItem(atPath: self.bulkDataLocalPath)
//                try FileManager.default.removeItem(atPath: self.setsLocalPath)
//                try FileManager.default.removeItem(atPath: self.keyruneLocalPath)
//                try FileManager.default.removeItem(atPath: self.cardsLocalPath)
//                try FileManager.default.removeItem(atPath: self.rulingsLocalPath)
//                try FileManager.default.removeItem(atPath: self.rulesLocalPath)
//            } catch {
//                print(error)
//                exit(EXIT_FAILURE)
//            }
            self.endActivity(label: label, from: dateStart)
            exit(EXIT_SUCCESS)
        }.catch { error in
            print(error)
            exit(EXIT_FAILURE)
        }
    }

    func createBulkData() -> Promise<Void> {
        return Promise { seal in
            let _ = bulkArray
            seal.fulfill(())
        }
    }
    
    func bulkData() -> [[String: Any]] {
        let bulkDataPath  = "\(cachePath)/\(ManaKit.Constants.ScryfallDate)_\(bulkDataFileName)"
        let data = try! Data(contentsOf: URL(fileURLWithPath: bulkDataPath))
        guard let dict = try! JSONSerialization.jsonObject(with: data,
                                                           options: .mutableContainers) as? [String: Any] else {
            fatalError("Malformed data")
        }
        guard let array = dict["data"] as? [[String: Any]] else {
            fatalError("Malformed data")
        }

        for dict in array {
            for (k,v) in dict {
                if k == "name" {
                    if let value = v as? String {
                        switch value {
                        case "All Cards":
                            self.cardsRemotePath = dict["download_uri"] as! String
                            self.cardsLocalPath = "\(cachePath)/\(self.cardsRemotePath.components(separatedBy: "/").last ?? "")"
                        case "Rulings":
                            self.rulingsRemotePath = dict["download_uri"] as! String
                            self.rulingsLocalPath = "\(cachePath)/\(self.rulingsRemotePath.components(separatedBy: "/").last ?? "")"
                        default:
                            ()
                        }
                    }
                }
            }
        }
        return array
    }
    
    // MARK: - Promise methods
    func fetchData(from remotePath: String, saveTo localPath: String) -> Promise<Void> {
        return Promise { seal in
            let willFetch = !FileManager.default.fileExists(atPath: localPath)
                
            if willFetch {
                guard let urlString = remotePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let url = URL(string: urlString) else {
                    fatalError("Malformed url")
                }

                var rq = URLRequest(url: url)
                rq.httpMethod = "GET"
                
                firstly {
                    URLSession.shared.downloadTask(.promise,
                                                   with: rq,
                                                   to: URL(fileURLWithPath: localPath))
                }.done { _ in
                    
                    seal.fulfill(())
                }.catch { error in
                    seal.reject(error)
                }
            } else {
                seal.fulfill(())
            }
        }
    }
    
    func createPromise(with query: String, parameters: [Any]?) -> Promise<Void> {
        return Promise { seal in
            execPG(query: query,
                   parameters: parameters)
            seal.fulfill(())
        }
    }
    
    func execPG(query: String, parameters: [Any]?) {
        do {
            let statement = try connection.prepareStatement(text: query)
            
            if let parameters = parameters {
                var convertibles = [PostgresValueConvertible]()
                for parameter in parameters {
                    if let c = parameter as? PostgresValueConvertible {
                        convertibles.append(c)
                    }
                }
                
                try statement.execute(parameterValues: convertibles)
            } else {
                try statement.execute()
            }
            
            statement.close()
        } catch {
            fatalError("\(error)")
        }
    }
    
    func execInSequence(label: String, promises: [()->Promise<Void>], completion: @escaping () -> Void) {
        var promise = promises.first!()
        let countTotal = promises.count
        var countIndex = 0

        let animation = PercentProgressAnimation(stream: stdoutStream,
                                                 header: "\(label) started on \(Date())")
        
        for next in promises {
            promise = promise.then { n -> Promise<Void> in
                countIndex += 1

                if countIndex % self.printMilestone == 0 {
//                    print("Exec... \(countIndex)/\(countTotal) \(Date())")
                    
                    animation.update(step: countIndex,
                                     total: countTotal,
                                     text: "Exec..")
                    
                }
                return next()
            }
        }
        promise.done {_ in
            animation.complete(success: true)
            print("\(label) done on \(Date())")
            completion()
        }.catch { error in
            print(error)
            completion()
        }
    }

    // MARK: - Utility methods
    func sectionFor(name: String) -> String? {
        if name.count == 0 {
            return nil
        } else {
            let letters = CharacterSet.letters
            var prefix = String(name.prefix(1))
            if prefix.rangeOfCharacter(from: letters) == nil {
                prefix = "#"
            }
            return prefix.uppercased().folding(options: .diacriticInsensitive, locale: .current)
        }
    }
    
    func displayFor(name: String) -> String {
        var display = ""
        let components = name.components(separatedBy: "_")
        
        if components.count > 1 {
            for e in components {
                var cap = e
                
                if e != "the" || e != "a" || e != "an" || e != "and" {
                    cap = e.prefix(1).uppercased() + e.dropFirst()
                }
                if display.count > 0 {
                    display.append(" ")
                }
                display.append(cap)
            }
        } else {
            display = name
        }
        
        return display
    }
    
    func capitalize(string: String) -> String {
        if string.count == 0 {
            return string
        } else {
            return (string.prefix(1).uppercased() + string.dropFirst()).replacingOccurrences(of: "_", with: " ")
        }
    }
    
    /*
     * Converts @param string into double equivalents i.e. 100.1a = 100.197
     * Useful for ordering in NSSortDescriptor.
     */
    func order(of string: String) -> Double {
        var termOrder = Double(0)
        
        if let num = Double(string) {
            termOrder = num
        } else {
            let digits = NSCharacterSet.decimalDigits
            var numString = ""
            var charString = ""
            
            for c in string.unicodeScalars {
                if c == "." || digits.contains(c) {
                    numString.append(String(c))
                } else {
                    charString.append(String(c))
                }
            }
            
            if let num = Double(numString) {
                termOrder = num
            }
            
            if charString.count > 0 {
                for c in charString.unicodeScalars {
                    let s = String(c).unicodeScalars
                    termOrder += Double(s[s.startIndex].value) / 100
                }
            }
        }
        return termOrder
    }
    
    func startActivity(label: String) -> Date {
        let date = Date()
        print("\(label) started on... \(date)")
        return date
    }
    
    func endActivity(label: String, from: Date) {
        let dateEnd = Date()
        let timeDifference = dateEnd.timeIntervalSince(from)
        
        print("\(label) ended on: \(dateEnd)")
        print("Elapsed time: \(format(timeDifference))")
    }

    func format(_ interval: TimeInterval) -> String {
        if interval == 0 {
            return "HH:mm:ss"
        }
        
        let seconds = interval.truncatingRemainder(dividingBy: 60)
        let minutes = (interval / 60).truncatingRemainder(dividingBy: 60)
        let hours = (interval / 3600)
        return String(format: "%.2d:%.2d:%.2d", Int(hours), Int(minutes), Int(seconds))
    }
}

