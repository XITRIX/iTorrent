//
//  Publisher+UI.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.05.2024.
//

import Combine
import Foundation

@MainActor
extension Publisher where Self.Failure == Never {

    /// Attaches a subscriber with closure-based behavior to a publisher that never fails and receives on Main Thread if needed.
    ///
    /// Use ``Publisher/sink(receiveValue:)`` to observe values received by the publisher and print them to the console. This operator can only be used when the stream doesn’t fail, that is, when the publisher’s ``Publisher/Failure`` type is <doc://com.apple.documentation/documentation/Swift/Never>.
    ///
    /// In this example, a <doc://com.apple.documentation/documentation/Swift/Range> publisher publishes integers to a ``Publisher/sink(receiveValue:)`` operator’s
    /// `receiveValue` closure that prints them to the console:
    ///
    ///     let integers = (0...3)
    ///     integers.publisher
    ///         .sink { print("Received \($0)") }
    ///
    ///     // Prints:
    ///     //  Received 0
    ///     //  Received 1
    ///     //  Received 2
    ///     //  Received 3
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// The return value should be held, otherwise the stream will be canceled.
    ///
    /// - parameter receiveValue: The closure to execute on receipt of a value.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func uiSink(receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        sink { value in
            runOnMainThreadIfNeeded {
                receiveValue(value)
            }
        }
    }
}

func runOnMainThreadIfNeeded(_ action: @escaping () -> Void) {
    if Thread.isMainThread {
        action()
    } else {
        DispatchQueue.main.async {
            action()
        }
    }
}
