// Credit https://github.com/heestand-xyz/AirKit

import UIKit
import SwiftUI

@available(visionOS, unavailable)
public class Air: ObservableObject {

    static let shared = Air()

    @Published
    public var connected: Bool = false {
        didSet {
            connectionCallbacks.forEach({ $0(connected) })
        }
    }
    private var connectionCallbacks: [(Bool) -> ()] = []

    private var airWindowScene: UIWindowScene?
    private var airWindow: UIWindow?

    private var superView: UIView?
    private var surfaceView: UIView?
    private var onSurfaceRestored: (@MainActor () -> Void)?
    private var hostingController: UIViewController?

    private var appIsActive: Bool { UIApplication.shared.applicationState == .active }

    private var sceneAccessoryRegistration: Any?
    private weak var sceneAccessoryRegistrar: UIViewController?

    init() {}

    private func check() {
        if let connectedScreen = airWindowScene {
            add(scene: connectedScreen) { success in
                guard success else { return }
                self.connected = true
            }
        }
    }

    public static func play(_ view: AnyView) {
        Air.shared.superView = nil
        Air.shared.surfaceView = nil
        Air.shared.onSurfaceRestored = nil
        Air.shared.hostingController = UIHostingController<AnyView>(rootView: view)
        Air.shared.check()
    }

    public static func play(
        _ view: UIView,
        onSurfaceRestored: (@MainActor () -> Void)? = nil
    ) {
        Air.shared.registerExternalDisplayAccessoryIfNeeded()
        Air.shared.superView = view.superview
        Air.shared.surfaceView = view
        Air.shared.onSurfaceRestored = onSurfaceRestored

        // Keep the external controller's root view stable. Making the video
        // surface itself the root view leaves it owned by that controller
        // after it is reparented to the phone, and tearing the external
        // window down can consequently invalidate VLC's rendering surface.
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        Air.shared.hostingController = vc
        Air.shared.check()
    }

    public static func stop() {
        Air.shared.unregisterExternalDisplayAccessory()
        Air.shared.connected = false
        Air.shared.remove()
        Air.shared.superView = nil
        Air.shared.surfaceView = nil
        Air.shared.onSurfaceRestored = nil
        Air.shared.hostingController = nil
    }

    func registerExternalDisplayAccessoryIfNeeded() {
#if compiler(>=6.4)
        guard #available(iOS 27.0, *),
              sceneAccessoryRegistration == nil,
              let registrar = UIApplication.shared.keySceneWindow?.rootViewController?.topPresented
        else { return }

        let configuration = UISceneConfiguration(name: "External Display Configuration", sessionRole: .windowExternalDisplayNonInteractive)
        configuration.delegateClass = AirPlaySceneDelegate.self

        let accessory = UISceneAccessory.externalNonInteractive(sceneConfiguration: configuration)
        let registration = registrar.registerSceneAccessory(accessory)
        registration.isEnabled = true

        sceneAccessoryRegistrar = registrar
        sceneAccessoryRegistration = registration
#endif
    }

    func unregisterExternalDisplayAccessory() {
#if compiler(>=6.4)
        guard #available(iOS 27.0, *),
              let registration = sceneAccessoryRegistration as? UISceneAccessoryRegistration
        else { return }

        sceneAccessoryRegistrar?.unregisterSceneAccessory(registration)
        sceneAccessoryRegistrar = nil
        sceneAccessoryRegistration = nil
#endif
    }


    public static func connection(_ callback: @escaping (Bool) -> ()) {
        Air.shared.connectionCallbacks.append(callback)
    }

    public func connect(windowScene: UIWindowScene) {
        // print("AirKit - Connect")
        add(scene: windowScene) { success in
            self.connected = success
        }
    }

    func add(scene: UIWindowScene, completion: @escaping (Bool) -> ()) {
        // print("AirKit - Add Screen")

        airWindowScene = scene

        guard let viewController: UIViewController = hostingController else {
            // print("AirKit - Add - Failed: Hosting Controller Not Found")
            completion(false)
            return
        }

        guard let airWindowScene else {
            // print("AirKit - Add - Failed: Window Scene Not Found")
            completion(false)
            return
        }
        let airWindow = UIWindow(windowScene: airWindowScene)
        airWindow.frame = airWindowScene.screen.bounds
        airWindow.rootViewController = viewController
        self.airWindow = airWindow

        if let _ = viewController as? UIHostingController<AnyView> {
            let traitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceIdiom: .tv),
                airWindowScene.traitCollection
            ])
            viewController.setOverrideTraitCollection(traitCollection, forChild: viewController)
        }

        airWindow.isHidden = false

        if let surfaceView {
            move(surfaceView, to: viewController.view)
        }
        // print("AirKit - Add Screen - Done")
        completion(true)
    }

    func disconnect(windowScene: UIWindowScene) {
        // print("AirKit - Disconnect")
        guard windowScene == airWindowScene else { return }

        // First detach the drawable from the external controller, then tear
        // its window down, and only then attach the drawable to the phone.
        // This produces an unambiguous external -> nil -> phone lifecycle.
        surfaceView?.removeFromSuperview()
        remove()

        if let superView, let surfaceView {
            move(surfaceView, to: superView)
            let restoreVideoOutput = onSurfaceRestored

            Task { @MainActor [weak superView, weak surfaceView, restoreVideoOutput] in
                await Task.yield()
                guard
                    let superView,
                    let surfaceView,
                    surfaceView.superview === superView
                else { return }

                superView.layoutIfNeeded()
                surfaceView.setNeedsLayout()
                surfaceView.layoutIfNeeded()
                restoreVideoOutput?()
            }
        }
        connected = false
    }

    private func move(_ view: UIView, to superView: UIView) {
        if view.superview !== superView {
            view.removeFromSuperview()
            superView.addSubview(view)
        }
        view.frame = superView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        superView.setNeedsLayout()
        view.setNeedsLayout()
    }

    func remove() {
        // print("AirKit - Remove")
        airWindow?.isHidden = true
        airWindow?.rootViewController = nil
        airWindow?.windowScene = nil
        airWindow = nil
        airWindowScene = nil
    }

    public static func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration? {
        guard connectingSceneSession.role == .windowExternalDisplayNonInteractive else { return nil }
        let configuration = UISceneConfiguration(name: "AirPlay Display", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = AirPlaySceneDelegate.self
        return configuration
    }
}

private class AirPlaySceneDelegate: UIResponder, UISceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        Air.shared.connect(windowScene: windowScene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        Air.shared.disconnect(windowScene: windowScene)
    }
}
