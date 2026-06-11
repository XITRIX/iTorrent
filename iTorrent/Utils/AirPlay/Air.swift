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
        Air.shared.hostingController = UIHostingController<AnyView>(rootView: view)
        Air.shared.check()
    }

    public static func play(_ view: UIView) {
        Air.shared.registerExternalDisplayAccessoryIfNeeded()
        Air.shared.superView = view.superview
        let vc = UIViewController()
        vc.view = view
        Air.shared.hostingController = vc
        Air.shared.check()
    }

    public static func stop() {
        Air.shared.unregisterExternalDisplayAccessory()
        Air.shared.remove()
        Air.shared.superView = nil
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
        self.connected = true

        add(scene: windowScene) { success in
            guard success else { return }
            self.connected = true
        }
    }

    func add(scene: UIWindowScene, completion: @escaping (Bool) -> ()) {
        // print("AirKit - Add Screen")

        airWindowScene = scene

        airWindow = UIWindow(frame: scene.screen.bounds)

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
        self.airWindow?.rootViewController = viewController
        self.airWindow?.windowScene = airWindowScene

        if let _ = viewController as? UIHostingController<AnyView> {
            let traitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceIdiom: .tv),
                airWindowScene.traitCollection
            ])
            viewController.setOverrideTraitCollection(traitCollection, forChild: viewController)
        }

        self.airWindow?.isHidden = false
        // print("AirKit - Add Screen - Done")
        completion(true)
    }

    func disconnect(windowScene: UIWindowScene) {
        // print("AirKit - Disconnect")
        guard windowScene == airWindowScene else { return }

        if let superView, let view = hostingController?.view {
            superView.addSubview(view)
            view.frame = superView.bounds
        }
        remove()
        connected = false
    }

    func remove() {
        // print("AirKit - Remove")
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

