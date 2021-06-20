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
        let query = "SELECT createOrUpdateServerUpdate($1)"
        let parameters = [isFullUpdate]
        
        return createPromise(with: query,
                             parameters: parameters)
    }
}
