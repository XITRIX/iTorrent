//
//  CombineLatest6.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/04/2024.
//

import Combine

public extension Publishers {
    /// A publisher that receives and combines the latest elements from four
    /// publishers.
    struct CombineLatest6<
        A: Publisher,
        B: Publisher,
        C: Publisher,
        D: Publisher,
        E: Publisher,
        F: Publisher
    >: Publisher where
        A.Failure == B.Failure,
        B.Failure == C.Failure,
        C.Failure == D.Failure,
        D.Failure == E.Failure,
        E.Failure == F.Failure
    {
        public typealias Output = (A.Output, B.Output, C.Output, D.Output, E.Output, F.Output)

        public typealias Failure = A.Failure

        public let a: A
        public let b: B
        public let c: C
        public let d: D
        public let e: E
        public let f: F

        public init(
            _ a: A,
            _ b: B,
            _ c: C,
            _ d: D,
            _ e: E,
            _ f: F
        ) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
        }

        public func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Downstream.Failure == Failure,
            Downstream.Input == Output
        {
            typealias Inner = CombineLatest6Inner<A.Output,
                B.Output,
                C.Output,
                D.Output,
                E.Output,
                                                  F.Output,
                Failure,
                Downstream>
            let inner = Inner(downstream: subscriber, upstreamCount: 6)
            a.subscribe(Inner.Side(index: 0, combiner: inner))
            b.subscribe(Inner.Side(index: 1, combiner: inner))
            c.subscribe(Inner.Side(index: 2, combiner: inner))
            d.subscribe(Inner.Side(index: 3, combiner: inner))
            e.subscribe(Inner.Side(index: 4, combiner: inner))
            f.subscribe(Inner.Side(index: 5, combiner: inner))
            subscriber.receive(subscription: inner)
        }
    }
}

extension Publishers.CombineLatest6: Equatable
    where
    A: Equatable,
    B: Equatable,
    C: Equatable,
    D: Equatable,
    E: Equatable,
    F: Equatable {}

private final class CombineLatest6Inner<Input0,
    Input1,
    Input2,
    Input3,
    Input4,
    Input5,
    Failure,
    Downstream: Subscriber>:
    AbstractCombineLatest<(Input0, Input1, Input2, Input3, Input4, Input5), Failure, Downstream>
    where Downstream.Input == (Input0, Input1, Input2, Input3, Input4, Input5),
    Downstream.Failure == Failure
{
    override func convert(values: [Any?]) -> (Input0, Input1, Input2, Input3, Input4, Input5) {
        return (values[0] as! Input0,
                values[1] as! Input1,
                values[2] as! Input2,
                values[3] as! Input3,
                values[4] as! Input4,
                values[5] as! Input5)
    }
}
