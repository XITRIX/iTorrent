import UIKit
import Bond
import ReactiveKit

class TestC: Codable {
    var a: String = "_C"
}

struct TestS: Codable {
    var a: String = "_S"
}

open class CObservable<T: Codable>: Observable<T>, Codable {
    private enum CodingKeys: String, CodingKey {
        case value
    }
    
    override init(_ value: T, subject: Subject<T, Never> = PassthroughSubject()) {
        super.init(value, subject: subject)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        super.init(try container.decode(T.self, forKey: .value))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
}

class Code: Codable {
    var a: String = ""
    var b = CObservable<String>("")
}

var obsC = CObservable(TestC())
var obsS = CObservable(TestS())

obsC.observeNext { obj in
    print(obj.a)
}

obsS.observeNext { obj in
    print(obj.a)
}

obsC.value.a = "C"
obsS.value.a = "S"
