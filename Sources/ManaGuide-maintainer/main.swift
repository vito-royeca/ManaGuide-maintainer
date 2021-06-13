import Foundation
import PromiseKit

ManaKit.sharedInstance.configure(apiURL: "http://192.168.1.182:1993",
                                         partnerKey: "ManaGuide",
                                         publicKey: ManaKit.Constants.TcgPlayerPublicKey,
                                         privateKey: ManaKit.Constants.TcgPlayerPrivateKey)

let maintainer = Maintainer()
maintainer.checkServerInfo()
// let t = test()

RunLoop.current.run() 

// class test {
//     init() {
//         var promises = [Promise<(data: Data, response: URLResponse)>]()

//         for i in 1...10 {
//             promises.append(promiseFactory(param: i))
//         }

//         firstly {
//             when(fulfilled: promises)
//         }.done { array in
//             for d in array {
//                 print(d.data.count)
//             }
//             exit(EXIT_SUCCESS)
//         }.catch { error in
//             print(error)
//             exit(EXIT_FAILURE)
//         }
//     }

//     func promiseFactory(param: Int) -> Promise<(data: Data, response: URLResponse)> {
//         let url = URL(string: "http://192.168.1.182:1993/images/cards/c21/en/\(param)/png.png")!
//         return URLSession.shared.dataTask(.promise, with: url)
//     }
// }


