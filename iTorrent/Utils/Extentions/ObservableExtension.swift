//
//  ObservableExtension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 26.10.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Bond

fileprivate enum CodingKeys: String, CodingKey {
    case value
}

extension Observable: Codable where Element: Codable {
    convenience public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try container.decode(Element.self, forKey: .value))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
}
