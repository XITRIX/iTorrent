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
    var connectionCallbacks: [(Bool) -> ()] = []

    var airScreen: UIScreen?
    var airWindow: UIWindow?

    var superView: UIView?
    var hostingController: UIViewController?

    var appIsActive: Bool { UIApplication.shared.applicationState == .active }

    init() {

        NotificationCenter.default.addObserver(self, selector: #selector(didConnect),
                                               name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnect),
                                               name: UIScreen.didDisconnectNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive),
                                               name: UIApplication.willResignActiveNotification, object: nil)
    }

    private func check() {
       if let connectedScreen = UIScreen.screens.first(where: { $0 != .main }) {
            add(screen: connectedScreen) { success in
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
        shared.superView = view.superview
        let vc = UIViewController()
        vc.view = view
        Air.shared.hostingController = vc
        Air.shared.check()
    }

    public static func stop() {
        Air.shared.remove()
        Air.shared.superView = nil
        Air.shared.hostingController = nil
    }

    public static func connection(_ callback: @escaping (Bool) -> ()) {
        Air.shared.connectionCallbacks.append(callback)
    }

    @objc func didConnect(sender: NSNotification) {
        // print("AirKit - Connect")
        self.connected = true
        guard let screen: UIScreen = sender.object as? UIScreen else { return }
        add(screen: screen) { success in
            guard success else { return }
            self.connected = true
        }
    }

    func add(screen: UIScreen, completion: @escaping (Bool) -> ()) {

        // print("AirKit - Add Screen")

        airScreen = screen

        airWindow = UIWindow(frame: airScreen!.bounds)

        guard let viewController: UIViewController = hostingController else {
            // print("AirKit - Add - Failed: Hosting Controller Not Found")
            completion(false)
            return
        }

        findWindowScene(for: airScreen!) { windowScene in
            guard let airWindowScene: UIWindowScene = windowScene else {
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

    }

    func findWindowScene(for screen: UIScreen, shouldRecurse: Bool = true, completion: @escaping (UIWindowScene?) -> ())  {
        // print("AirKit - Find Window Scene")
        var matchingWindowScene: UIWindowScene? = nil
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            if let windowScene = scene as? UIWindowScene {
                if windowScene.screen == screen {
                    matchingWindowScene = windowScene
                    break
                }
            }
        }
        guard let windowScene: UIWindowScene = matchingWindowScene else {
            // Only recurse once to avoid infinite loops
            if shouldRecurse {
               Task { @MainActor in
                    self.findWindowScene(for: screen, shouldRecurse: false) { windowScene in
                        completion(windowScene)
                    }
                }
            } else {
                completion(nil)
            }
            return
        }
        completion(windowScene)
    }

    @objc func didDisconnect() {
        // print("AirKit - Disconnect")
        if let superView, let view = hostingController?.view {
            superView.addSubview(view)
            view.frame = superView.bounds
        }
        remove()
        connected = false
    }

    func remove() {
        // print("AirKit - Remove")
        airWindow = nil
        airScreen = nil
    }

    @objc func didBecomeActive() {
        // print("AirKit - App Active")
    }

    @objc func willResignActive() {
        // print("AirKit - App Inactive")

    }

}
