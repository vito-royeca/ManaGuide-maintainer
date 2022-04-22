//
//  Maintainer+ServerUpdate.swift
//  ManaKit
//
//  Created by Vito Royeca on 12/7/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import PromiseKit

extension Maintainer {
    func processServerUpdatePromise() -> Promise<Void> {
        let query = "SELECT createServerUpdate($1)"
        let parameters = [isFullUpdate]
        
        print("processServerUpdatePromise()...")
        return createPromise(with: query,
                             parameters: parameters)
    }
    
    func processServerVacuumPromise() -> Promise<Void> {
        let query = "VACUUM FULL ANALYZE"
        
        print("processServerVacuumPromise()...")
        return createPromise(with: query,
                             parameters: nil)
    }
}
