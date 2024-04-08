//
//  Published+Codable.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 07.04.2024.
//

import Combine

fileprivate enum CodingKeys: String, CodingKey {
    case value
}

extension Published: Decodable where Value: Decodable {
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try .init(from: decoder))
    }
}

extension Published: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        try unofficialValue.encode(to: encoder)
    }
}

private class PublishedWrapper<T> {
    @Published private(set) var value: T

    init(_ value: Published<T>) {
        _value = value
    }
}

private extension Published {
    var unofficialValue: Value {
        PublishedWrapper(self).value
    }
}
