//
//  Box.swift
//  BinderTest
//
//  Created by Daniil Vinogradov on 21.05.2020.
//  Copyright © 2020 NoNameDude. All rights reserved.
//

import Foundation

open class Box<T> {
    public typealias ListenerNew = (_ new: T) -> ()
    public typealias ListenerOldNew = (_ old: T?, _ new: T) -> ()
    
    private var id: Int = 0
    private var listeners = [Int: ListenerOldNew]()
    private var boxBindingListeners = [String: ListenerOldNew]()
    private var stopNotifing = false
    private let hash: String
    
    public let disposalBag = DisposalBag()
    
    public var variable: T {
        didSet {
            notifyUpdate(old: oldValue, new: variable)
        }
    }
    
    public init(_ variable: T) {
        self.variable = variable
        hash = UUID().uuidString
    }
    
    public func notifyUpdate() {
        notifyUpdate(old: variable, new: variable)
    }
    
    public func bind(updateOnBind: Bool = true, _ listener: @escaping ListenerNew) -> Disposal {
        if updateOnBind { listener(variable) }
        
        id += 1
        listeners[id] = { _, new in
            listener(new)
        }
        return Disposal { [id] in
            self.listeners[id] = nil
        }
    }
    
    public func bind(updateOnBind: Bool = true, _ listener: @escaping ListenerOldNew) -> Disposal {
        if updateOnBind { listener(nil, variable) }
        
        id += 1
        listeners[id] = listener
        return Disposal { [id] in
            self.listeners[id] = nil
        }
    }
    
    public func bindTo(_ box: Box<T>) -> Disposal {
        let disp1 = box.internalBind(hash: hash) { [weak self] value in
            guard let self = self else { return }
            
            let old = self.variable
            self.updateWithoutNotify(value)
            self.notifyUpdate(old: old, new: self.variable, without: [box.hash])
        }
        
        let disp2 = internalBind(hash: box.hash) { [weak self] value in
            guard let self = self else { return }
            
            let old = box.variable
            box.updateWithoutNotify(value)
            box.notifyUpdate(old: old, new: box.variable, without: [self.hash])
        }
        
        return Disposal {
            disp1.dispose()
            disp2.dispose()
        }
    }
    
    public func multiplyUpdate(_ updateAction: () -> ()) {
        let old = variable
        stopNotifing = true
        updateAction()
        stopNotifing = false
        notifyUpdate(old: old, new: variable)
    }
    
    public func updateWithoutNotify(_ updateAction: () -> ()) {
        stopNotifing = true
        updateAction()
        stopNotifing = false
        
    }
    
//    func convert<U>(_ convertion: (T) -> (U)) -> Box<U> {
//        Box<U>(convertion(variable))
//    }
}

extension Box {
    private func notifyUpdate(old: T, new: T, without: [String] = []) {
        DispatchQueue.main.async {
            self.boxBindingListeners.filter { !without.contains($0.key) }.values.forEach { $0(old, new) }
            if self.stopNotifing { return }
            self.listeners.values.forEach { $0(old, new) }
        }
    }
    
    private func internalBind(hash: String, updateOnBind: Bool = true, _ listener: @escaping ListenerNew) -> Disposal {
        if updateOnBind { listener(variable) }
        
        boxBindingListeners[hash] = { _, new in
            listener(new)
        }
        
        return Disposal { [hash] in
            self.boxBindingListeners[hash] = nil
        }
    }
    
    private func updateWithoutNotify(_ value: T) {
        stopNotifing = true
        variable = value
        stopNotifing = false
    }
}

class EBox<T: Equatable>: Box<T>, Equatable {
    static func == (lhs: EBox<T>, rhs: EBox<T>) -> Bool {
        return lhs.variable == rhs.variable
    }
}

class HBox<T: Hashable>: EBox<T>, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(variable)
    }
}
