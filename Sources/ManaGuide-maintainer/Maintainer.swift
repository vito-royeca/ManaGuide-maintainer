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
    let printMilestone     = 3000
    let bulkDataFileName   = "scryfall-bulkData.json"
    let setsFileName       = "scryfall-sets.json"
    let keyruneFileName    = "keyrune.html"
    let rulesFileName      = "MagicCompRules.txt"
    let milestoneFileName  = "milestone.json"
    let cachePath          = "/tmp"
    
    // MARK: - Variables
    var tcgplayerAPIToken  = ""
    var filePrefix         = ""
    var milestone          = Milestone(value: 0, fileOffset: UInt64(0))
    
    // remote file names
    let bulkDataRemotePath = "https://api.scryfall.com/bulk-data"
    var cardsRemotePath    = ""
    var rulingsRemotePath  = ""
    let setsRemotePath     = "https://api.scryfall.com/sets"
    let keyruneRemotePath  = "https://keyrune.andrewgioia.com/cheatsheet.html"
    let rulesRemotePath    = "https://media.wizards.com/2021/downloads/MagicCompRules 20211115.txt"

    // local file names
    var bulkDataLocalPath  = ""
    var cardsLocalPath     = ""
    var rulingsLocalPath   = ""
    var setsLocalPath      = ""
    var keyruneLocalPath   = ""
    var rulesLocalPath     = ""
    var milestoneLocalPath = ""
    
    // caches
    var artistsCache      = [String]()
    var raritiesCache     = [String]()
    var languagesCache    = [[String: String]]()
    var watermarksCache   = [String]()
    var layoutsCache      = [[String: String]]()
    var framesCache       = [[String: String]]()
    var frameEffectsCache = [[String: String]]()
    var colorsCache       = [[String: Any]]()
    var formatsCache      = [String]()
    var legalitiesCache   = [String]()
    var typesCache        = [[String: Any]]()
    var componentsCache   = [String]()
    
    // TCGPlayer
    public enum TCGPlayer {
        public static let apiVersion = "v1.36.0"
        public static let apiLimit   = 300
        public static let partnerKey = "ManaGuide"
        public static let publicKey  = "A49D81FB-5A76-4634-9152-E1FB5A657720"
        public static let privateKey = "C018EF82-2A4D-4F7A-A785-04ADEBF2A8E5"
    }
    
    // lazy variables
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

    // options variables
    var host: String
    var port: Int
    var database: String
    var user: String
    var password: String
    var isFullUpdate: Bool
    var imagesPath: String
    
    // MARK: - init

    init(host: String,
         port: Int,
         database: String,
         user: String,
         password: String,
         isFullUpdate: Bool,
         imagesPath: String) {
        self.host = host
        self.port = port
        self.database = database
        self.user = user
        self.password = password
        self.isFullUpdate = isFullUpdate
        self.imagesPath = imagesPath
    }
    
    // MARK: - Database methods

    func createConnection() -> Connection {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = host
        configuration.port = port
        configuration.database = database
        configuration.user = user
        configuration.credential = .cleartextPassword(password: password)
        configuration.ssl = false
        
        do {
            let connection = try PostgresClientKit.Connection(configuration: configuration)
        
            return connection
        } catch {
            fatalError("\(error)")
        }
    }
    
    func updateDatabase() {
        let label = "Managuide Maintainer"
        let dateStart = startActivity(label: label)
        let completion = {
            do {
                if FileManager.default.fileExists(atPath: self.bulkDataLocalPath) {
                    try FileManager.default.removeItem(atPath: self.bulkDataLocalPath)
                }
                if FileManager.default.fileExists(atPath: self.setsLocalPath) {
                    try FileManager.default.removeItem(atPath: self.setsLocalPath)
                }
                if FileManager.default.fileExists(atPath: self.keyruneLocalPath) {
                    try FileManager.default.removeItem(atPath: self.keyruneLocalPath)
                }
                if FileManager.default.fileExists(atPath: self.cardsLocalPath) {
                    try FileManager.default.removeItem(atPath: self.cardsLocalPath)
                }
                if FileManager.default.fileExists(atPath: self.rulingsLocalPath) {
                    try FileManager.default.removeItem(atPath: self.rulingsLocalPath)
                }
                if FileManager.default.fileExists(atPath: self.rulesLocalPath) {
                    try FileManager.default.removeItem(atPath: self.rulesLocalPath)
                }
                if FileManager.default.fileExists(atPath: self.milestoneLocalPath) {
                    try FileManager.default.removeItem(atPath: self.milestoneLocalPath)
                }
            } catch {
                print(error)
            }
            self.endActivity(label: label, from: dateStart)
            exit(EXIT_SUCCESS)
        }
        var promises = [()->Promise<Void>]()

        promises.append({
            return Promise { seal in
                print("Managuide starting...")
                seal.fulfill(())
            }
        })
        
        if isFullUpdate {
            filePrefix         = "managuide-\(Date().timeIntervalSince1970)"
            bulkDataLocalPath  = "\(cachePath)/\(filePrefix)_\(bulkDataFileName)"
            setsLocalPath      = "\(cachePath)/\(filePrefix)_\(setsFileName)"
            keyruneLocalPath   = "\(cachePath)/\(filePrefix)_\(keyruneFileName)"
            rulesLocalPath     = "\(cachePath)/\(filePrefix)_\(rulesFileName)"
            milestoneLocalPath = "\(cachePath)/\(milestoneFileName)"
            
            readMilestone()
            
            // downloads
            promises.append({
                self.fetchData(from: self.bulkDataRemotePath, saveTo: self.bulkDataLocalPath)
            })
            promises.append({
                self.createBulkData()
            })
            promises.append({
                self.fetchData(from: self.setsRemotePath, saveTo: self.setsLocalPath)
            })
            promises.append({
                self.fetchData(from: self.keyruneRemotePath, saveTo: self.keyruneLocalPath)
            })
            promises.append({
                self.fetchData(from: self.cardsRemotePath, saveTo: self.cardsLocalPath)
            })
            promises.append({
                self.fetchData(from: self.rulingsRemotePath, saveTo: self.rulingsLocalPath)
            })
            promises.append({
                self.fetchData(from: self.rulesRemotePath, saveTo: self.rulesLocalPath)
            })
            
//             updates
            promises.append({
                self.fetchCardImages()
            })
            promises.append({
                self.processSetsData()
            })
            promises.append({
                self.processCardsData(type: .misc)
            })
            promises.append({
                self.processCardsData(type: .cards)
            })
            promises.append({
                self.processCardsData(type: .partsAndFaces)
            })
            promises.append({
                self.processRulingsData()
            })
            promises.append({
                self.processOtherCardsData()
            })
            promises.append({
                self.processComprehensiveRulesData()
            })
        }
        
        promises.append({
            self.processPricingData()
        })
        promises.append({
            self.processServerUpdatePromise()
        })
        promises.append({
            self.processServerVacuumPromise()
        })

        execInSequence(label: label,
                       promises: promises,
                       completion: completion)
    }

    // MARK: - Bulk Data methods
    func createBulkData() -> Promise<Void> {
        return Promise { seal in
            let _ = bulkArray
            seal.fulfill(())
        }
    }
    
    func bulkData() -> [[String: Any]] {
        let data = try! Data(contentsOf: URL(fileURLWithPath: bulkDataLocalPath))
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
                let convertibles = parameters.compactMap({
                    $0 as? PostgresValueConvertible
                })
                
                try statement.execute(parameterValues: convertibles)
            } else {
                try statement.execute()
            }
            
            statement.close()
        } catch {
            print(error)
        }
    }
    
    func execInSequence(label: String, promises: [()->Promise<Void>], completion: @escaping () -> Void) {
        var promise = promises.first!()
        let countTotal = promises.count
        var countIndex = 0

        let animation = PercentProgressAnimation(stream: stdoutStream,
                                                 header: "\(label)")

        for next in promises {
            promise = promise.then { n -> Promise<Void> in
                countIndex += 1

                if countIndex == countTotal {
                    animation.update(step: countIndex,
                                     total: countTotal,
                                     text: "Done")
                } else {
                    if countIndex % 2 == 0 {
                        animation.update(step: countIndex,
                                         total: countTotal,
                                         text: "Exec...")
                    }
                }
                return next()
            }
        }
        promise.done {_ in
            animation.complete(success: true)
            completion()
        }.catch { error in
            print(error)
        }
    }

    // MARK: - Utility methods
    
    func readFileData(fileReader: StreamingFileReader, lines: Int) -> [[String: Any]] {
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
        let endDate = Date()
        let timeDifference = endDate.timeIntervalSince(from)
        
        print("\(label) ended on: \(endDate)")
        print("Elapsed time: \(format(timeDifference))")
        print("")
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

