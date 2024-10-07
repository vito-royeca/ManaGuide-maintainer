//
//  Maintainer+ServerUpdate.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 12/7/19.
//

extension Maintainer {
    func processServerUpdate() async throws {
        let query = "SELECT createServerUpdate($1)"
        let parameters = [isFullUpdate]
        
        print("processServerUpdate()...")
        try await exec(query: query, with: parameters)
    }
    
    func processServerVacuum() async throws {
        print("processServerVacuum()...")
        try await exec(query: "VACUUM FULL ANALYZE")
    }
}
