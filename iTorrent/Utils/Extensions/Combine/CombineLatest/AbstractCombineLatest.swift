//
//  AbstractCombineLatest.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/04/2024.
//

import Combine

internal class AbstractCombineLatest<Output, Failure, Downstream: Subscriber>
    where Downstream.Input == Output, Downstream.Failure == Failure
{
    private let downstream: Downstream

    // TODO: The size of these arrays always stays the same.
    // Maybe we can leverage ManagedBuffer/ManagedBufferPointer here
    // to avoid additional allocations.
    private var buffers: [Any?] // 0x78
    private var subscriptions: [Subscription?] // 0x80

    private var demand = Subscribers.Demand.none // 0x88

    private var recursion = false // 0x90

    private var finished = false // 0x98

    private var errored = false // 0xA0

    private var cancelled = false // 0xA8

    private let upstreamCount: Int // 0xB0

    private var finishCount = 0 // 0xB8

    private let lock = UnfairLock.allocate() // 0xC0

    private let downstreamLock = UnfairRecursiveLock.allocate() // 0xC8

    internal init(downstream: Downstream, upstreamCount: Int) {
        self.downstream = downstream
        self.buffers = Array(repeating: nil, count: upstreamCount)
        self.subscriptions = Array(repeating: nil, count: upstreamCount)
        self.upstreamCount = upstreamCount
    }

    deinit {
        lock.deallocate()
        downstreamLock.deallocate()
    }

    // TODO: There should be more type-safe (and faster) way.
    // E. g. what if we store `buffers` in subclasses?
    internal func convert(values: [Any?]) -> Output {
        abstractMethod()
    }

    fileprivate final func receive(subscription: Subscription, index: Int) {
        lock.lock()
        guard !cancelled && subscriptions[index] == nil else {
            lock.unlock()
            subscription.cancel()
            return
        }
        subscriptions[index] = subscription
        lock.unlock()
    }

    fileprivate final func receive(_ input: Any, index: Int) -> Subscribers.Demand {
        lock.lock()
        if cancelled || finished {
            lock.unlock()
            return .none
        }
        buffers[index] = input
        guard !recursion && demand > 0 && buffers.allSatisfy({ $0 != nil }) else {
            lock.unlock()
            return .none
        }
        demand -= 1
        recursion = true
        lock.unlock()
        downstreamLock.lock()
        let newDemand = downstream.receive(convert(values: buffers))
        downstreamLock.unlock()
        lock.lock()
        recursion = false
        demand += newDemand
        lock.unlock()
        return .none
    }

    fileprivate final func receive(completion: Subscribers.Completion<Failure>,
                                   index: Int) {
        switch completion {
        case .finished:
            lock.lock()
            if finished {
                lock.unlock()
                return
            }
            finishCount += 1
            subscriptions[index] = nil
            if finishCount == upstreamCount {
                finished = true
                buffers = Array(repeating: nil, count: upstreamCount)
                lock.unlock()
                downstreamLock.lock()
                downstream.receive(completion: completion)
                downstreamLock.unlock()
            } else {
                lock.unlock()
            }
        case .failure:
            lock.lock()
            finished = true
            errored = true
            let subscriptions = self.subscriptions
            self.subscriptions = Array(repeating: nil, count: upstreamCount)
            buffers = Array(repeating: nil, count: upstreamCount)
            lock.unlock()
            for (i, subscription) in subscriptions.enumerated() where i != index {
                subscription?.cancel()
            }
            downstreamLock.lock()
            downstream.receive(completion: completion)
            downstreamLock.unlock()
        }
    }
}

extension AbstractCombineLatest: Subscription {
    internal func request(_ demand: Subscribers.Demand) {
//        demand.assertNonZero() // TODO: Test this
        lock.lock()
        guard !cancelled && !finished else {
            lock.unlock()
            return
        }
        self.demand += demand
        lock.unlock()
        for subscription in subscriptions {
            subscription?.request(demand)
        }
    }

    internal func cancel() {
        lock.lock()
        cancelled = true
        let subscriptions = self.subscriptions
        self.subscriptions = Array(repeating: nil, count: upstreamCount)
        buffers = Array(repeating: nil, count: upstreamCount)
        lock.unlock()
        for subscription in subscriptions {
            subscription?.cancel()
        }
    }
}

extension AbstractCombineLatest: CustomStringConvertible {
    internal var description: String { return "CombineLatest" }
}

extension AbstractCombineLatest: CustomReflectable {
    internal var customMirror: Mirror {
        lock.lock()
        defer { lock.unlock() }
        let children: [Mirror.Child] = [
            ("downstream", downstream),
            ("upstreamSubscriptions", subscriptions),
            ("demand", demand),
            ("buffers", buffers)
        ]
        return Mirror(self, children: children)
    }
}

extension AbstractCombineLatest: CustomPlaygroundDisplayConvertible {
    internal final var playgroundDescription: Any { return description }
}

extension AbstractCombineLatest {
    internal struct Side<Input>: Subscriber, CustomStringConvertible {
        private let index: Int
        private let combiner: AbstractCombineLatest

        internal let combineIdentifier = CombineIdentifier()

        internal init(index: Int, combiner: AbstractCombineLatest) {
            self.index = index
            self.combiner = combiner
        }

        internal func receive(subscription: Subscription) {
            combiner.receive(subscription: subscription, index: index)
        }

        internal func receive(_ input: Input) -> Subscribers.Demand {
            return combiner.receive(input, index: index)
        }

        internal func receive(completion: Subscribers.Completion<Failure>) {
            combiner.receive(completion: completion, index: index)
        }

        internal var description: String { return "CombineLatest" }
    }
}

internal func abstractMethod(file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("Abstract method call", file: file, line: line)
}
