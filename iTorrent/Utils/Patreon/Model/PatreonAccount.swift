//
//  PatreonAccount.swift
//  AltStore
//
//  Created by Riley Testut on 8/20/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import CoreData

extension PatreonAPI {
    struct AccountResponse: Decodable {
        struct Data: Decodable {
            struct Attributes: Decodable {
                var first_name: String?
                var full_name: String
            }
            
            var id: String
            var attributes: Attributes
        }
        
        var data: Data
        var included: [PatronResponse]?
    }
}

extension PatreonAPI {
    struct MemberResponse: Decodable {
        struct PledgeEvent: Codable {
            struct Attributes: Codable {
                var amount_cents: Int
                var currency_code: String
                var payment_status: String?
                var tier_id: String
            }
            
            var id: String
            var attributes: Attributes
        }
        
        var included: [PledgeEvent]?
    }
}

class PatreonAccount: Codable {
    var identifier: String
    
    var name: String
    var firstName: String?
    var id: String?
    
    var isPatron: Bool
    var fullVersion: Bool = false
    
    var hideAds: Bool {
        get { isPatron || fullVersion }
    }
    
    var fixedAccount: Bool = false
    
    init(response: PatreonAPI.AccountResponse) {
        self.identifier = response.data.id
        self.name = response.data.attributes.full_name
        self.firstName = response.data.attributes.first_name
        self.fullVersion = UserPreferences.patreonCredentials?.benefits.fullVersion.contains(self.identifier) ?? false
        
        if let patronResponse = response.included?.first {
            let patron = Patron(response: patronResponse)
            self.isPatron = (patron.status == .active)
            self.id = patron.identifier
        } else {
            self.isPatron = false
        }
    }
    
    init(identifier: String, name: String, firstName: String) {
        self.identifier = identifier
        self.name = name
        self.firstName = firstName
        self.isPatron = false
        self.fullVersion = UserPreferences.patreonCredentials?.benefits.fullVersion.contains(self.identifier) ?? false
        self.fixedAccount = true
    }
    
    func applyPledgeHistory(pledgeHistory: [PatreonAPI.MemberResponse.PledgeEvent]) {
        fullVersion = pledgeHistory.contains(where: { pledge in
            Tier.Rewards.fullVersion.contains(pledge.attributes.tier_id) &&
                pledge.attributes.payment_status == "Paid"
        })
    }
}
