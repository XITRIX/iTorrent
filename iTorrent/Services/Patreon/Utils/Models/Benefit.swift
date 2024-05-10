//
//  Benefit.swift
//  AltStore
//
//  Created by Riley Testut on 8/21/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation

extension PatreonService {
    struct BenefitResponse: Decodable {
        var id: String
    }
}

enum ALTPatreonBenefitType: String {
    case fullVersion = "1958127"
    case credits = "1984996"
}

struct Benefit: Hashable {
    var type: ALTPatreonBenefitType

    init(response: PatreonService.BenefitResponse) {
        self.type = ALTPatreonBenefitType(rawValue: response.id)!
    }
}
