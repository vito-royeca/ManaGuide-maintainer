import Foundation
//import PMJSON
import PromiseKit

ManaKit.sharedInstance.configure(apiURL: "http://192.168.1.182:1993",
                                         partnerKey: "ManaGuide",
                                         publicKey: ManaKit.Constants.TcgPlayerPublicKey,
                                         privateKey: ManaKit.Constants.TcgPlayerPrivateKey)

let maintainer = Maintainer()
maintainer.checkServerInfo()

RunLoop.current.run() 

//class test {
//    func cardsData() -> [[String: Any]] {
//        let cachePath = "/tmp"
//        let cardsPath = "\(cachePath)/all-cards-20210612211705.json"
//        JSON.decodeStream
////        let decoder = JSONDecoder()
////        decoder.decode(Decodable.Protocol., from: <#T##Data#>)
//        
//        let data = try! Data(contentsOf: URL(fileURLWithPath: cardsPath), options: .mappedIfSafe)
//        guard let array = try! JSONSerialization.jsonObject(with: data,
//                                                            options: .allowFragments) as? [[String: Any]] else {
//            fatalError("Malformed data")
//        }
//        
//        return array
//    }
//}

/*
let fileReader = StreamingFileReader(path: logFile)
while let line = fileReader.readLine() {
    // Do something with the line
}

class StreamingFileReader {
    var fileHandle: FileHandle?
    var buffer: Data
    let bufferSize: Int = 1024
    
    // Using new line as the delimiter
    let delimiter = "\n".data(using: .utf8)!
    
    init(path: String) {
        fileHandle = FileHandle(forReadingAtPath: path)
        buffer = Data(capacity: bufferSize)
    }
    
    func readLine() -> String? {
        var rangeOfDelimiter = buffer.range(of: delimiter)
        
        while rangeOfDelimiter == nil {
            guard let chunk = fileHandle?.readData(ofLength: bufferSize) else { return nil }
            
            if chunk.count == 0 {
                if buffer.count > 0 {
                    defer { buffer.count = 0 }
                    
                    return String(data: buffer, encoding: .utf8)
                }
                
                return nil
            } else {
                buffer.append(chunk)
                rangeOfDelimiter = buffer.range(of: delimiter)
            }
        }
        
        let rangeOfLine = 0 ..< rangeOfDelimiter!.upperBound
        let line = String(data: buffer.subdata(in: rangeOfLine), encoding: .utf8)
        
        buffer.removeSubrange(rangeOfLine)
        
        return line?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
*/
