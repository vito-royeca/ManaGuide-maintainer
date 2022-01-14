//
//  Maintainer+Images.swift
//  ManaKit
//
//  Created by Vito Royeca on 1/12/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import PostgresClientKit
import PromiseKit

struct Milestone : Codable {
    var value: Int
    var fileOffset: UInt64
}
struct CardStatus : Codable {
    var status: String
}

extension Maintainer {
    func fetchCardImages() -> Promise<Void> {
        return Promise { seal in
            let label = "fetchCardImages"
            let date = self.startActivity(label: label)
            let callback = {
                self.endActivity(label: label, from: date)
                seal.fulfill()
            }
            
            let fileReader = StreamingFileReader(path: cardsLocalPath)
            self.loopReadCards(fileReader: fileReader, start: 0, callback: callback)
        }
    }
    
    private func loopReadCards(fileReader: StreamingFileReader, start: Int, callback: @escaping () -> Void) {
        if start + milestone.value <= milestone.value &&
            milestone.fileOffset != 0 {
            print("seeking to milestone: \(milestone.value), offset: \(milestone.fileOffset)")
            fileReader.seek(toOffset: milestone.fileOffset)
        }
        
        let label = "readCardsData"
        let date = self.startActivity(label: label)
        let cards = self.readFileData(fileReader: fileReader, lines: self.printMilestone)
        
        if !cards.isEmpty {
            let index = start + cards.count
            let label2 = "downloadCardImages"
            var promises = [()->Promise<Void>]()
            
            for card in cards {
                promises.append(contentsOf: self.createImageDownloadPromises(dict: card))
            }
            
            if !promises.isEmpty {
                self.execInSequence(label: "\(label2): \(milestone.value)",
                                    promises: promises,
                                    completion: {
                                        self.milestone.value += cards.count
                                        self.milestone.fileOffset = fileReader.offset
                                        self.writeMilestone()
                                        self.endActivity(label: "\(label)", from: date)
                                        self.loopReadCards(fileReader: fileReader, start: index, callback: callback)
                                        
                })
            } else {
                self.endActivity(label: "\(label)", from: date)
                self.loopReadCards(fileReader: fileReader, start: index, callback: callback)
            }
        } else {
            callback()
        }
    }
    
    private func createImageDownloadPromises(dict: [String: Any]) -> [()->Promise<Void>] {
        var promises = [()->Promise<Void>]()
        var filteredData = [[String: Any]]()
        
        guard let number = dict["collector_number"] as? String,
              let language = dict["lang"] as? String,
              let set = dict["set"] as? String else {
            return promises
        }
        
        let cleanNumber = number.replacingOccurrences(of: "★", with: "star")
                                .replacingOccurrences(of: "†", with: "cross")
        
        if let imageStatus = dict["image_status"] as? String,
            let imageUrisDict = dict["image_uris"] as? [String: String] {
            let imageUrisDict = createImageUris(number: cleanNumber,
                                                set: set,
                                                language: language,
                                                imageStatus: imageStatus,
                                                imageUrisDict: imageUrisDict)
            filteredData.append(imageUrisDict)
        }
        
        if let faces = dict["card_faces"] as? [[String: Any]] {
            for i in 0...faces.count-1 {
                let face = faces[i]
                
                if let imageStatus = dict["image_status"] as? String,
                    let imageUrisDict = face["image_uris"] as? [String: String] {
                    let faceImageUrisDict = createImageUris(number: "\(cleanNumber)_\(i)",
                                                            set: set,
                                                            language: language,
                                                            imageStatus: imageStatus,
                                                            imageUrisDict: imageUrisDict)
                    filteredData.append(faceImageUrisDict)
                }
            }
        }
        
        promises.append(contentsOf: filteredData.map { dict in
            return {
                return self.createImageDownloadPromise(dict: dict)
            }
        })

        return promises
    }
    
    private func createImageDownloadPromise(dict: [String: Any]) -> Promise<Void> {
        return Promise { seal in
            guard let number = dict["number"] as? String,
                let language = dict["language"] as? String,
                let set = dict["set"] as? String,
                let imageStatus = dict["imageStatus"] as? String,
                let imageUris = dict["imageUris"] as? [String: String] else {
                
                let error = NSError(domain: "Error",
                                    code: 500,
                                    userInfo: [NSLocalizedDescriptionKey: "Wrong download keys"])
                seal.reject(error)
                return
            }
            
            let path   = "\(imagesPath)/\(set)/\(language)/\(number)"
            var promises = [Promise<Void>]()
            
            for (k,v) in imageUris {
                if !(k == "art_crop" || k == "normal" || k == "png") ||
                    (v.hasSuffix("soon.jpg") || v.hasSuffix("soon.png")) {
                    continue
                }
                
                var imageFile = "\(path)/\(k)"
                var willDownload = false
                
                if v.lowercased().contains(".png") {
                    imageFile = "\(imageFile).png"
                } else if v.lowercased().contains(".jpg") {
                    imageFile = "\(imageFile).jpg"
                }
                
                if FileManager.default.fileExists(atPath: imageFile) {
                    if let status = self.readStatus(directoryPath: path) {
                        if imageStatus != status {
                            willDownload = true
                        }
                    } else {
                        willDownload = true
                    }
                } else {
                    willDownload = true
                }
                
                if willDownload {
                    promises.append(downloadImagePromise(url: v,
                                                         destinationFile: imageFile))
                }
            }

            if promises.isEmpty {
                seal.fulfill(())
            } else {
                firstly {
                    when(fulfilled: promises)
                }.done {
                    print("Downloaded \(set)/\(language)/\(number)")
                    self.writeStatus(directoryPath: path, status: imageStatus)
                    seal.fulfill(())
                }.catch { error in
                    print("Error downloading: \(set)/\(language)/\(number)")
                    print("\(error)")
                    self.writeStatus(directoryPath: path, status: "")
                    seal.fulfill(())
                }
            }
        }
    }
    
    private func createImageUris(number: String, set: String, language: String, imageStatus: String, imageUrisDict: [String: String]) -> [String: Any] {
        var newDict = [String: Any]()
        
        // remove the key (?APIKEY) in the url
        var newImageUris = [String: String]()
        for (k,v) in imageUrisDict {
            newImageUris[k] = v//.components(separatedBy: "?").first
        }
    
        newDict["number"]      =  number
        newDict["language"]    =  language
        newDict["set"]         =  set
        newDict["imageStatus"] =  imageStatus
        newDict["imageUris"]   =  newImageUris
        
        return newDict
    }
    
    private func downloadImagePromise(url: String, destinationFile: String) -> Promise<Void> {
        return Promise { seal in
            firstly {
                URLSession.shared.dataTask(.promise, with: URL(string: url)!)
            }.done { response in
                do {
                    self.prepare(destinationFile: destinationFile)
                    try response.data.write(to: URL(fileURLWithPath: destinationFile))
//                    print("Downloaded \(destinationFile)")
                    seal.fulfill(())
                } catch {
                    print("Unable to write to: \(destinationFile)")
                    seal.fulfill()
                }
            }.catch { error in
                print("\(error): \(destinationFile)")
                seal.fulfill(())
            }
        }
    }
    
    private func copyImagePromise(sourceFile: String, destinationFile: String) -> Promise<Void> {
        return Promise { seal in
            do {
                prepare(destinationFile: destinationFile)
                try FileManager.default.copyItem(at: URL(fileURLWithPath: sourceFile),
                                                 to: URL(fileURLWithPath: destinationFile))
//                print("Copied \(destinationFile)")
                seal.fulfill(())
            } catch {
                print("Unable to write to: \(destinationFile)")
                seal.fulfill()
            }
        }
    }
    
    // MARK: - File methods
    
    func readMilestone() {
        guard FileManager.default.fileExists(atPath: milestoneLocalPath) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: milestoneLocalPath), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            milestone = try decoder.decode(Milestone.self, from: data)
        } catch {
            milestone = Milestone(value: 0, fileOffset: UInt64(0))
        }
    }
    
    func writeMilestone() {
        do {
            if FileManager.default.fileExists(atPath: milestoneLocalPath) {
                try FileManager.default.removeItem(atPath: milestoneLocalPath)
            }
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(milestone)
            
            FileManager.default.createFile(atPath: milestoneLocalPath,
                                           contents: data,
                                           attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func readStatus(directoryPath: String) -> String? {
        var statusFile = "\(directoryPath)/status.txt"
        
        if FileManager.default.fileExists(atPath: statusFile) {
            do {
                var status = try String(contentsOfFile: statusFile)
                status = status.trimmingCharacters(in: .whitespacesAndNewlines)
                try FileManager.default.removeItem(atPath: statusFile)
                writeStatus(directoryPath: directoryPath, status: status)
                return status
            } catch {
                return nil
            }
        } else {
            statusFile = "\(directoryPath)/status.json"
            
            if FileManager.default.fileExists(atPath: statusFile) {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: statusFile), options: .mappedIfSafe)
                    let decoder = JSONDecoder()
                    let cardStatus = try decoder.decode(CardStatus.self, from: data)
                    return cardStatus.status
                } catch {
                    return nil
                }
            }
        }
        
        return nil
    }
    
    private func writeStatus(directoryPath: String, status: String) {
        let statusFile = "\(directoryPath)/status.json"
        
        do {
            if FileManager.default.fileExists(atPath: statusFile) {
                try FileManager.default.removeItem(atPath: statusFile)
            }
            
            let cardStatus = CardStatus(status: status)
            let encoder = JSONEncoder()
            let data = try encoder.encode(cardStatus)
            
            self.prepare(destinationFile: statusFile)
            FileManager.default.createFile(atPath: statusFile,
                                           contents: data,
                                           attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func prepare(destinationFile: String) {
        do {
            let destinationURL = URL(fileURLWithPath: destinationFile)
            let parentDir = destinationURL.deletingLastPathComponent().path
            
            // create parent dirs
            if !FileManager.default.fileExists(atPath: parentDir) {
                try! FileManager.default.createDirectory(atPath: parentDir,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
            }
            
            // delete if existing
            if FileManager.default.fileExists(atPath: destinationFile) {
                try FileManager.default.removeItem(atPath: destinationFile)
            }
        } catch {
            print(error)
        }
    }
}
