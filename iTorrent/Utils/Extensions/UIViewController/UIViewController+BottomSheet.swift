//
//  UIViewController+BottomSheet.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 10.04.2024.
//

import Combine
import UIKit

// MARK: Bottom Sheet
public extension UIViewController {
    func applyBottomSheetDetents(with scrollView: UIScrollView? = nil, and extra: Double = 0, dismissInSeconds: Double? = nil, showGrabber: Bool = false, delegate: UISheetPresentationControllerDelegate? = nil) -> AnyCancellable? {
        guard #available(iOS 15.0, *),
              let sheet = sheetPresentationController
        else { return nil }

        sheet.prefersGrabberVisible = showGrabber
        if let delegate {
            sheet.delegate = delegate
        }
        /// If UIScrollView is not presented,
        /// or iOS 16 is not available, than set default detents
        guard let scrollView,
              #available(iOS 16.0, *)
        else {
            sheet.detents = [.medium(), .large()]
            return nil
        }

        sheet.detents = [.custom(resolver: { context in
            let maxHeight = scrollView.contentSize.height + scrollView.adjustedContentInset.top + extra
            let targetHeight = min(maxHeight, context.maximumDetentValue)

            scrollView.bounces = maxHeight > context.maximumDetentValue

            // No idea why, but iPhone SE 3d gen (iOS 17.4) constantly gives zero size no matter what content is,
            // but maxing it with RANDOM non zero height (44) recalculates scroll's size properly
            return max(targetHeight, 44)
        })]

        if #available(iOS 26, *) {
            view.backgroundColor = .clear
            scrollView.backgroundColor = .clear
        }

        return scrollView.publisher(for: \.contentSize, options: .new)
            .removeDuplicates()
            .sink { [unowned self, weak sheet] val in
                UIView.performWithoutAnimation {
                    view.layoutIfNeeded()
                }
                sheet?.animateChanges {
                    sheet?.invalidateDetents()
                }
                if let dismissInSeconds {
                    DispatchQueue.main.asyncAfter(deadline: .now() + dismissInSeconds) {
                        guard let _ = sheet else { return }
                        self.dismiss(animated: true)
                    }
                }
            }
    }
}

