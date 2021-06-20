import Foundation
import PromiseKit
import ArgumentParser

// Define our parser.
struct Managuide: ParsableCommand {
    @Option(help: "Database host.")
    var host: String
    
    @Option(help: "Database port.")
    var port: Int
    
    @Option(help: "Database name.")
    var database: String
    
    @Option(help: "Database user.")
    var user: String
    
    @Option(help: "Database password.")
    var password: String
    
    @Option(help: "Full update: true | false")
    var fullUpdate: Bool
    
    func run() throws {
        ManaKit.sharedInstance.configure(apiURL: "http://192.168.1.182:1993",
                                                 partnerKey: "ManaGuide",
                                                 publicKey: ManaKit.Constants.TcgPlayerPublicKey,
                                                 privateKey: ManaKit.Constants.TcgPlayerPrivateKey)

        let maintainer = Maintainer(host: host,
                                    port: port,
                                    database: database,
                                    user: user,
                                    password: password,
                                    isFullUpdate: fullUpdate)
        maintainer.updateDatabase()
    }
}

// Run the parser.
Managuide.main()

// wait until all threads are done before exiting
RunLoop.current.run()





