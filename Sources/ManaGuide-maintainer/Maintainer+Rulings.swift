//
//  Maintainer+Rulings.swift
//  ManaGuide-maintainer
//
//  Created by Vito Royeca on 14/07/2019.
//

import Foundation

extension Maintainer {
    func processRulingsData() async throws {
        let label = "processRulingsData"
        let date = startActivity(label: label)
        var processes = [() async throws -> Void]()

        processes.append({
            try await self.createDeleteRulings()

        })
        for dict in rulingsArray {
            processes.append({
                try await self.createRuling(dict: dict)

            })
        }
        
        try await execInSequence(label: label,
                                 processes: processes)
        endActivity(label: label, from: date)
    }
    
    func rulingsData() -> [[String: Any]] {
        let rulingsPath = "\(cachePath)/\(rulingsRemotePath.components(separatedBy: "/").last ?? "")"
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: rulingsPath))
        guard let array = try! JSONSerialization.jsonObject(with: data,
                                                            options: .mutableContainers) as? [[String: Any]] else {
            fatalError("Malformed data")
        }
        
        return array
    }
}
