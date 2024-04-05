//
//  BackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import Foundation

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
    public static let shared = BackgroundService()

    var isRunning: Bool { impl.isRunning }

    @discardableResult
    func start() -> Bool {
        impl.start()
    }

    func stop() {
        guard isRunning else { return }
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
