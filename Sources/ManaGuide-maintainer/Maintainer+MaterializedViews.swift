//
//  Maintainer+MaterializedViews.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 6/2/25.
//

import Foundation
import PostgresClientKit

extension Maintainer {
    func processMaterializedViews() async throws {
        let label = "processMaterializedViews"
        let date = startActivity(label: label)
        var processes = [() async throws -> Void]()
        
        processes.append({
            try await self.processSetsMaterializedView()
        })
        
        if let sets = try await fetchSets() {
            for set in sets {
                processes.append({
                    try await self.processSetMaterializedView(set: set)
                })
            }
        }

        try await exec(processes: processes)
        endActivity(label: label, from: date)
    }
    
    private func processSetMaterializedView(set: [String: Any]) async throws {
        if let code = set["code"] as? String,
           let languages = set["languages"] as? [[String: Any]] {

            let startDate = Date()
            var processes1 = [() async throws -> Void]()
            var processes2 = [() async throws -> Void]()
            
            for language in languages {
                if let languageCode = language["code"] as? String {
                    processes1.append({
                        try await self.createSetMaterializedView(code: code, language: languageCode)
                    })
                    processes2.append({
                        try await self.updateSetMaterializedView(code: code, language: languageCode)
                    })
                }
            }

            try await exec(processes: processes1)
            try await exec(processes: processes2)

            let endDate = Date()
            let timeDifference = endDate.timeIntervalSince(startDate)
        }
    }

    private func processSetsMaterializedView() async throws {
        let startDate = Date()
        var processes = [() async throws -> Void]()
        
        processes.append({
            try await self.createSetsMaterializedView()
        })
        
        processes.append({
            try await self.updateSetsMaterializedView()
        })

        try await exec(processes: processes)
        let endDate = Date()
        let timeDifference = endDate.timeIntervalSince(startDate)
        print("setsMaterializedView Elapsed time: \(format(timeDifference))")
    }

    func deleteSetMaterializedView(code: String, language: String) async throws {
        let query = "DROP MATERIALIZED VIEW IF EXISTS matv_cmset_\(code)_\(language)"
        try await exec(query: query)
    }
    
    func createSetMaterializedView(code: String, language: String) async throws {
        let query = "SELECT createSetMaterializedView($1,$2)"
        let parameters = [code, language]
        try await exec(query: query, with: parameters)
    }
    
    func updateSetMaterializedView(code: String, language: String) async throws {
        let query = "SELECT updateSetMaterializedView($1,$2)"
        let parameters = [code, language]
        try await exec(query: query, with: parameters)
    }
    
    func createSetsMaterializedView() async throws {
        let query = "SELECT createSetsMaterializedView()"
        try await exec(query: query)
    }

    func updateSetsMaterializedView() async throws {
        let query = "SELECT updateSetsMaterializedView()"
        try await exec(query: query)
    }
}
