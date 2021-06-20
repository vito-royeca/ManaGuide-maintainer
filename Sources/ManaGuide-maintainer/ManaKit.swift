//
//  Manakit.swift
//  ManaKit
//
//  Created by Jovito Royeca on 11/04/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

public class ManaKit {
    public enum Constants {
        public static let TcgPlayerApiVersion = "v1.36.0"
        public static let TcgPlayerApiLimit   = 300
        public static let TcgPlayerPublicKey  = "A49D81FB-5A76-4634-9152-E1FB5A657720"
        public static let TcgPlayerPrivateKey = "C018EF82-2A4D-4F7A-A785-04ADEBF2A8E5"
    }
    
    // MARK: - Shared Instance
    public static let sharedInstance = ManaKit()
    
    // MARK: - Variables
    var tcgPlayerPartnerKey: String?
    var tcgPlayerPublicKey: String?
    var tcgPlayerPrivateKey: String?
    var apiURL = ""
    
    
    // MARK: - Resource methods
    public func configure(apiURL: String, partnerKey: String, publicKey: String?, privateKey: String?) {
        self.apiURL = apiURL
        tcgPlayerPartnerKey = partnerKey
        tcgPlayerPublicKey = publicKey
        tcgPlayerPrivateKey = privateKey
    }

}
