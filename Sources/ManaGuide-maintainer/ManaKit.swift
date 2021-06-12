//
//  Manakit.swift
//  ManaKit
//
//  Created by Jovito Royeca on 11/04/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//
//@available(iOS 10, *)
//import UIKit
//@available(OSX 10, *)
//import NSKit

//import KeychainAccess
//import PromiseKit
//import SDWebImage
//import Sync

public class ManaKit {
    public enum Constants {
        public static let ScryfallDate        = "2021-06-09 09:16 UTC"
        public static let EightEditionRelease = "2003-07-28"
        public static let ManaGuideDataAge    = 24 * 3 // 3 days
        public static let TcgPlayerApiVersion = "v1.36.0"
        public static let TcgPlayerApiLimit   = 300
        public static let TcgPlayerPricingAge = 24 * 3 // 3 days
        public static let TcgPlayerPublicKey  = "A49D81FB-5A76-4634-9152-E1FB5A657720"
        public static let TcgPlayerPrivateKey = "C018EF82-2A4D-4F7A-A785-04ADEBF2A8E5"
        public static let MomModel            = "2020-01-30.mom"
    }
    
    public enum ImageName: String {
        case cardCircles       = "images/Card_Circles",
        cardBackCropped        = "images/cardback-crop-hq",
        cardBack               = "images/cardback-hq",
        collectorsCardBack     = "images/collectorscardback-hq",
        cropBack               = "images/cropback-hq",
        grayPatterned          = "images/Gray_Patterned_BG",
        intlCollectorsCardBack = "images/internationalcollectorscardback-hq"
    }
    
    public enum UserDefaultsKeys {
        public static let ScryfallDate          = "ScryfallDate"
        public static let KeyruneVersion        = "KeyruneVersion"
        public static let MTGJSONVersion        = "kMTGJSONVersion"
        public static let TcgPlayerToken        = "TcgPlayerToken"
        public static let TcgPlayerExpiration   = "TcgPlayerExpiration"
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
