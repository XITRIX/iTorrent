//
//  Campaign.swift
//  AltStore
//
//  Created by Riley Testut on 8/21/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation

extension PatreonService {
    struct CampaignResponse: Decodable {
        var id: String
    }
}

struct Campaign {
    var identifier: String

    init(response: PatreonService.CampaignResponse) {
        self.identifier = response.id
    }
}
