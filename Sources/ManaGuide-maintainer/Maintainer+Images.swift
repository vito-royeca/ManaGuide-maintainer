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
//import CryptoKit
import PostgresClientKit
import PromiseKit

extension Maintainer {
    func fetchCardImages() -> Promise<Void> {
        return Promise { seal in
            let cardsPath = "\(self.cachePath)/\(self.cardsRemotePath.components(separatedBy: "/").last ?? "")"
            let fileReader = StreamingFileReader(path: cardsPath)
            let label = "fetchCardImages"
            
            let date = self.startActivity(label: label)
            self.loopReadCards(fileReader: fileReader, start: 0, callback: {
                self.endActivity(label: label, from: date)
                seal.fulfill()
            })
        }
    }
    
    private func loopReadCards(fileReader: StreamingFileReader, start: Int, callback: @escaping () -> Void) {
        let label = "readCardsData"
        let date = self.startActivity(label: label)
        let cards = self.readFileData(fileReader: fileReader, lines: self.printMilestone)
        
        if !cards.isEmpty {
            let index = start + cards.count
            var promises = [()->Promise<Void>]()
            let label2 = "downloadCardImages"
            
            for card in cards {
                promises.append(contentsOf: self.createImageDownloadPromises(dict: card))
            }
            
            if !promises.isEmpty {
                self.execInSequence(label: "\(label2): \(index)",
                                    promises: promises,
                                    completion: {
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
        
        if let imageStatus = dict["image_status"] as? String,
            let imageUrisDict = dict["image_uris"] as? [String: String] {
            let imageUrisDict = createImageUris(number: number.replacingOccurrences(of: "★", with: "star"),
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
                    let faceImageUrisDict = createImageUris(number: "\(number.replacingOccurrences(of: "★", with: "star"))_\(i)",
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
            
            let imagesPath   = "\(imagesPath)/\(set)/\(language)/\(number)"
            var promises = [Promise<Void>]()
            
            for (k,v) in imageUris {
                var imageFile = "\(imagesPath)/\(k)"
                var remoteImageData: Data?
                var willDownload = false
                
                if v.lowercased().hasSuffix("png") {
                    imageFile = "\(imageFile).png"
                } else if v.lowercased().hasSuffix("jpg") {
                    imageFile = "\(imageFile).jpg"
                }
                
                if FileManager.default.fileExists(atPath: imageFile) {
                    if let directoryStatus = self.readStatus(directoryPath: imagesPath) {
                        if imageStatus != directoryStatus.trimmingCharacters(in: .whitespacesAndNewlines) {
                            willDownload = true
                        }
                    } else {
                        if k == "art_crop" || k == "normal" || k == "png" {
                            self.writeStatus(directoryPath: imagesPath, status: imageStatus)
                        }
                    }
                } else {
                    if v.hasSuffix("soon.jpg") || v.hasSuffix("soon.png") {
                        willDownload = false
                    } else {
                        if k == "art_crop" || k == "normal" || k == "png" {
                            self.writeStatus(directoryPath: imagesPath, status: imageStatus)
                        }
                        willDownload = true
                    }
                }

                if willDownload {
                    if k == "art_crop" || k == "normal" || k == "png" {
                        if let remoteImageData = remoteImageData {
                            promises.append(saveImagePromise(imageData: remoteImageData,
                                                             destinationFile: imageFile))
                        } else {
                            promises.append(downloadImagePromise(url: v,
                                                                 destinationFile: imageFile))
                        }
                    }
                }
            }

            if promises.isEmpty {
                seal.fulfill(())
            } else {
                firstly {
                    when(fulfilled: promises)
                }.done {
                    seal.fulfill(())
                }.catch { error in
                    print(error)
                    seal.fulfill(())
                }
            }
        }
    }
    
    private func readStatus(directoryPath: String) -> String? {
        let statusFile = "\(directoryPath)/status.txt"
        
        guard FileManager.default.fileExists(atPath: statusFile) else {
            return nil
        }
        
        do {
            let status = try String(contentsOfFile: statusFile)
            return status
        } catch {
            return nil
        }
    }
    
    private func writeStatus(directoryPath: String, status: String) {
        let statusFile = "\(directoryPath)/status.txt"
        
        if status != (self.readStatus(directoryPath: directoryPath) ?? "").trimmingCharacters(in: .whitespacesAndNewlines) {
            if FileManager.default.fileExists(atPath: statusFile) {
                try! FileManager.default.removeItem(atPath: statusFile)
            }
            
            self.prepare(destinationFile: statusFile)
            try! status.write(toFile: statusFile, atomically: true, encoding: .utf8)
        }
    }
    
//    private func compare(localFile local: String, andRemoteFile remote: String) -> Bool {
//        do {
//            let localImageData = try Data(contentsOf: URL(fileURLWithPath: local))
//            let remoteImageData = try Data(contentsOf: URL(string: remote)!)
//            let localMD5 = Insecure.MD5.hash(data: localImageData).map { String(format: "%02hhx", $0) }.joined()
//            let remoteMD5 = Insecure.MD5.hash(data: remoteImageData).map { String(format: "%02hhx", $0) }.joined()
//            return localMD5 == remoteMD5
//        } catch { error in
//            print(error)
//            return false
//        }
//    }

    private func createImageUris(number: String, set: String, language: String, imageStatus: String, imageUrisDict: [String: String]) -> [String: Any] {
        var newDict = [String: Any]()
        
        // remove the key (?APIKEY) in the url
        var newImageUris = [String: String]()
        for (k,v) in imageUrisDict {
            newImageUris[k] = v.components(separatedBy: "?").first
        }
    
        newDict["number"]      =  number
        newDict["language"]    =  language
        newDict["set"]         =  set
        newDict["imageStatus"] =  imageStatus
        newDict["imageUris"]   =  newImageUris
        
        return newDict
    }
    
    private func saveImagePromise(imageData: Data, destinationFile: String) -> Promise<Void> {
        return Promise { seal in
            do {
                prepare(destinationFile: destinationFile)
                try imageData.write(to: URL(fileURLWithPath: destinationFile))
//                print("Saved \(destinationFile)")
                seal.fulfill(())
            } catch {
                print("Unable to write to: \(destinationFile)")
                seal.fulfill()
            }
        }
    }
    
    private func downloadImagePromise(url: String, destinationFile: String) -> Promise<Void> {
        return Promise { seal in
            firstly {
                URLSession.shared.dataTask(.promise, with: URL(string: url)!)
            }.done { response in
                do {
                    self.prepare(destinationFile: destinationFile)
                    try response.data.write(to: URL(fileURLWithPath: destinationFile))
//                    print("Downloaded \(url)")
                    seal.fulfill(())
                } catch {
                    print("Unable to write to: \(destinationFile)")
                    seal.fulfill()
                }
            }.catch { error in
                print("\(error): \(url)")
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
