//
//  SceneDelegate+AVPlayer.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 16.06.2024.
//

import AVKit
import MvvmFoundation

extension SceneDelegate {
    func registerAVPlayer(in container: Container) {
        container.registerSingleton(factory: { [unowned self] in
            let vc = AVPlayerViewController()
            vc.delegate = avPlayerDeledates
            return vc
        })
    }
}

extension SceneDelegate {
    class AVPlayerDelegates: DelegateObject<SceneDelegate>, AVPlayerViewControllerDelegate {
        func playerViewControllerRestoreUserInterfaceForFullScreenExit(_ playerViewController: AVPlayerViewController) async -> Bool {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    guard let vc = parent.window?.rootViewController?.topPresented else {
                        return continuation.resume(returning: false)
                    }

                    vc.present(playerViewController, animated: true) {
                        continuation.resume(returning: true)
                    }
                }
            }
        }

        func playerViewControllerRestoreUserInterfaceForPictureInPictureStop(_ playerViewController: AVPlayerViewController) async -> Bool {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    guard let vc = parent.window?.rootViewController?.topPresented else {
                        return continuation.resume(returning: false)
                    }

                    vc.present(playerViewController, animated: true) {
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }

    private enum Keys {
        nonisolated(unsafe) static var avPlayerDeledates: Void?
    }

    private var avPlayerDeledates: AVPlayerDelegates {
        if let obj = objc_getAssociatedObject(self, &Keys.avPlayerDeledates) as? AVPlayerDelegates {
            return obj
        }

        let obj = AVPlayerDelegates(parent: self)
        objc_setAssociatedObject(self, &Keys.avPlayerDeledates, obj, .OBJC_ASSOCIATION_RETAIN)
        return obj
    }
}
