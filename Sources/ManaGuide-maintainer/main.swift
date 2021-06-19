import Foundation
import PMJSON
import PromiseKit

ManaKit.sharedInstance.configure(apiURL: "http://192.168.1.182:1993",
                                         partnerKey: "ManaGuide",
                                         publicKey: ManaKit.Constants.TcgPlayerPublicKey,
                                         privateKey: ManaKit.Constants.TcgPlayerPrivateKey)

let maintainer = Maintainer()

maintainer.updateDatabase()
RunLoop.current.run()



