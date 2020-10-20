//
//  CObservable.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 20.10.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Bond
import ReactiveKit

typealias CObservable = CodableProperty

public final class CodableProperty<Value: Codable>: PropertyProtocol, SubjectProtocol, BindableProtocol, DisposeBagProvider, Codable {

    private let lock = NSRecursiveLock(name: "com.reactive_kit.property")

    private let subject: Subject<Value, Never>

    public var bag: DisposeBag {
        return subject.disposeBag
    }
    
    /// Underlying value. Changing it emits `.next` event with new value.
    private var _value: Value
    public var value: Value {
        get {
            lock.lock(); defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock(); defer { lock.unlock() }
            _value = newValue
            subject.send(newValue)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case value
    }
    
    public init(_ value: Value, subject: Subject<Value, Never> = PassthroughSubject()) {
        _value = value
        self.subject = subject
    }

    required public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try container.decode(Value.self, forKey: .value))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
    
    public func on(_ event: Signal<Value, Never>.Event) {
        lock.lock(); defer { lock.unlock() }
        if case .next(let element) = event {
            _value = element
        }
        subject.on(event)
    }
    
    public func observe(with observer: @escaping (Signal<Value, Never>.Event) -> Void) -> Disposable {
        lock.lock(); defer { lock.unlock() }
        return subject.prepend(_value).observe(with: observer)
    }
    
    public var readOnlyView: AnyCodableProperty<Value> {
        return AnyCodableProperty(property: self)
    }
    
    /// Change the underlying value without notifying the observers.
    public func silentUpdate(value: Value) {
        lock.lock(); defer { lock.unlock() }
        _value = value
    }
    
    public func bind(signal: Signal<Value, Never>) -> Disposable {
        return signal
            .prefix(untilOutputFrom: bag.deallocated)
            .receive(on: ExecutionContext.nonRecursive())
            .observeNext { [weak self] element in
                self?.on(.next(element))
            }
    }
    
    deinit {
        subject.send(completion: .finished)
    }
}

/// Represents mutable state that can be observed as a signal of events.
public final class AnyCodableProperty<Value: Codable>: PropertyProtocol, SignalProtocol, Codable {
    
    private let property: CodableProperty<Value>
    
    public var value: Value {
        return property.value
    }
    
    public init(property: CodableProperty<Value>) {
        self.property = property
    }
    
    public func observe(with observer: @escaping (Signal<Value, Never>.Event) -> Void) -> Disposable {
        return property.observe(with: observer)
    }
}

