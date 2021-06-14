import Foundation
import PMJSON
import PromiseKit

ManaKit.sharedInstance.configure(apiURL: "http://192.168.1.182:1993",
                                         partnerKey: "ManaGuide",
                                         publicKey: ManaKit.Constants.TcgPlayerPublicKey,
                                         privateKey: ManaKit.Constants.TcgPlayerPrivateKey)

let maintainer = Maintainer()
maintainer.checkServerInfo()

RunLoop.current.run()

//var index = 0
//doPromises(line: index)
//RunLoop.current.run()
//
//func doPromises(line: Int) {
//    firstly {
//        read(lineNum: line)
//    }.then { string in
//        tempPromise(line: string)
//    }.done { result in
//        index = index+1
//        print(line)
//        
//        if result {
//            doPromises(line: index)
//        }
//    }.catch { error in
//        print("error")
//    }
//}
//
//func read(lineNum: Int) -> Promise<String> {
//    return Promise { seal in
//        let fileReader = StreamingFileReader(path: "/tmp/all-cards-20210613091740.json")
//        var cleanLine = ""
//        var currentLineNum = 0
//        
//        while let line = fileReader.readLine() {
//            if !line.hasPrefix("{") {
//                continue
//            }
//            
//            if currentLineNum == lineNum {
//                cleanLine = String(line)
//                if cleanLine.hasSuffix("}},") {
//                    cleanLine.removeLast()
//                }
//                break
//            } else {
//                currentLineNum += 1
//            }
//        }
//        seal.fulfill(cleanLine)
//    }
//}
//
//func tempPromise(line: String) -> Promise<Bool> {
//    return Promise { seal in
//        if line.isEmpty {
//            seal.fulfill(false)
//        } else {
//            do {
//                let json = try JSON.decode(line)
//                seal.fulfill(true)
//            } catch {
//                seal.fulfill(false)
//            }
//        }
//    }
//}

