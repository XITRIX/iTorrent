//
//  UIViewController+BottomSheet.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 10.04.2024.
//

import UIKit

// MARK: Bottom Sheet
public extension UIViewController {
    func applyBottomSheetDetents(with calc: @escaping () -> CGFloat) {
#if !os(visionOS)
        if let sheet = sheetPresentationController {
            sheet.prefersGrabberVisible = true

            /// If UIScrollView is not presented,
            /// or iOS 16 is not available, than set default detents
            guard #available(iOS 16.0, *)
            else {
                sheet.detents = [.medium(), .large()]
                return
            }

            sheet.detents = [.custom(resolver: { context in
                let height = calc()// + view.layoutMargins.top
                return min(height, context.maximumDetentValue)
            })]
        }
#endif
    }

    func applyBottomSheetDetents(with scrollView: UIScrollView? = nil) {
#if !os(visionOS)
        if let sheet = sheetPresentationController {
            sheet.prefersGrabberVisible = true

            /// If UIScrollView is not presented,
            /// or iOS 16 is not available, than set default detents
            guard let scrollView,
                  #available(iOS 16.0, *)
            else {
                sheet.detents = [.medium(), .large()]
                return
            }

            sheet.detents = [.custom(resolver: { [unowned self] context in
                let height = scrollView.contentSize.height + view.layoutMargins.top
                return min(height, context.maximumDetentValue)
            })]
        }
#endif
    }

    func invalidateBottomSheetDetents() {
#if !os(visionOS)
        if #available(iOS 16.0, *) {
            // Delay invalidation to allow all UI calculations perform first
            DispatchQueue.main.async { [self] in
                if let sheet = sheetPresentationController {
                    sheet.animateChanges {
                        sheet.invalidateDetents()
                    }
                }
            }
        }
#endif
    }
}
