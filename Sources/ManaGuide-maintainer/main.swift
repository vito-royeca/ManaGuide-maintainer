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
    
    func run() throws {
        ManaKit.sharedInstance.configure(apiURL: "http://192.168.1.182:1993",
                                                 partnerKey: "ManaGuide",
                                                 publicKey: ManaKit.Constants.TcgPlayerPublicKey,
                                                 privateKey: ManaKit.Constants.TcgPlayerPrivateKey)

        let maintainer = Maintainer(host: host,
                                    port: port,
                                    database: database,
                                    user: user,
                                    password: password)
        maintainer.updateDatabase()
    }
}

// Run the parser.
Managuide.main()

// or...
//let maintainer = Maintainer(host: "host",
//                            port: 5432,
//                            database: "managuide_prod",
//                            user: "managuide",
//                            password: "querida")
//maintainer.updateDatabase()

// wait until all threads are done before exiting
RunLoop.current.run()





