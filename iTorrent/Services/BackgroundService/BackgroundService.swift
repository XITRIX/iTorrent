//
//  BackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import Foundation
import Combine

@MainActor
protocol BackgroundServiceProtocol {
    var isRunning: Bool { get }
    func start() -> Bool
    func stop()
    func prepare() async -> Bool
}

extension BackgroundService {
    enum Mode: Codable {
        case audio
        case location
    }
}

class BackgroundService: BackgroundServiceProtocol {
    @Published var isRunningPublisher: Bool = false

    public static let shared = BackgroundService()

    var isRunning: Bool { impl.isRunning }

    @discardableResult
    func start() -> Bool {
        let res = impl.start()
        isRunningPublisher = res
        return res
    }

    func stop() {
        guard isRunning else { return }
        isRunningPublisher = false
        impl.stop()
    }

    func prepare() async -> Bool {
        await impl.prepare()
    }

    func applyMode(_ mode: Mode) async -> Bool {
        switch mode {
        case .audio:
            impl = AudioBackgroundService()
        case .location:
            impl = LocationBackgroundService()
        }
        return await impl.prepare()
    }

    private var impl: BackgroundServiceProtocol = AudioBackgroundService()
}
