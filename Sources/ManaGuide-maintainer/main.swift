import Foundation
import ArgumentParser

// Define our parser.
struct Managuide: ParsableCommand {
    @Option(help: "Database host")
    var host: String
    
    @Option(help: "Database port")
    var port: Int
    
    @Option(help: "Database name")
    var database: String
    
    @Option(help: "Database user")
    var user: String
    
    @Option(help: "Database password")
    var password: String
    
    @Option(help: "Full update: true | false")
    var fullUpdate: Bool
    
    @Option(help: "Card images path")
    var imagesPath: String

    func run() throws {
        let maintainer = Maintainer(host: host,
                                    port: port,
                                    database: database,
                                    user: user,
                                    password: password,
                                    isFullUpdate: fullUpdate,
                                    imagesPath: imagesPath)
        maintainer.updateDatabase()
    }
}

//#if DEBUG
let maintainer = Maintainer(host: "postgres.macarena",
                            port: 5432,
                            database: "managuide_dev3",
                            user: "managuide_dev",
                            password: "f1c6796717576d06c311c8bdffbbf9a1",
                            isFullUpdate: true,
                            imagesPath: "/Users/vitoroyeca/workspace/ManaGuide/tmp/managuide-images/cards")
maintainer.updateDatabase()
//#else
//Managuide.main()
//#endif

// wait until all threads are done before exiting
RunLoop.current.run()






