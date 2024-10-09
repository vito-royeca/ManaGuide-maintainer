//
//  Maintainer+IO.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 10/9/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Maintainer {
    func loopReadCards(label: String,
                       fileReader: StreamingFileReader,
                       offset: Int,
                       useMilestone: Bool,
                       callback: ([[String: Any]]) -> [() async throws -> Void]) async throws {
        if useMilestone {
            if offset + milestone.value <= milestone.value &&
                milestone.fileOffset != 0 {
                print("seeking to milestone: \(milestone.value), offset: \(milestone.fileOffset)")
                fileReader.seek(toOffset: milestone.fileOffset)
            }
        }
        
        let cards = readFileData(fileReader: fileReader, lines: self.printMilestone)
        
        guard !cards.isEmpty else {
            return
        }

        let index = offset + cards.count
        let processes = callback(cards)
        
        if !processes.isEmpty {
            let startDate = Date()
            try await exec(processes: processes)
            
            if useMilestone {
                milestone.value += cards.count
                milestone.fileOffset = fileReader.offset
                writeMilestone()
            }
            
            let endDate = Date()
            let timeDifference = endDate.timeIntervalSince(startDate)
            print("\(label): \(offset) Elapsed time: \(format(timeDifference))")
        }

        try await loopReadCards(label: label,
                                fileReader: fileReader,
                                offset: index,
                                useMilestone: useMilestone,
                                callback: callback)
    }

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

    func fetchData(from remotePath: String, saveTo localPath: String) async throws {
        guard !FileManager.default.fileExists(atPath: localPath) else {
            return
        }
            
        guard let urlString = remotePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString) else {
            fatalError("Malformed url")
        }

        let (localURL, _) = try await URLSession.shared.asyncDownload(from: url)
        try FileManager.default.moveItem(atPath: localURL.path, toPath: localPath)
    }

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
    
    func readStatus(directoryPath: String) -> String? {
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
    
    func writeStatus(directoryPath: String, status: String) {
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
    
    func prepare(destinationFile: String) {
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
    
    func startActivity(label: String) -> Date {
        let date = Date()
        print("\(label) started on: \(localFormat(date))")
        return date
    }
    
    func endActivity(label: String, from: Date) {
        let endDate = Date()
        let timeDifference = endDate.timeIntervalSince(from)
        
        print("\(label) ended   on: \(localFormat(endDate))")
        print("Elapsed time: \(format(timeDifference))\n")
    }
}
