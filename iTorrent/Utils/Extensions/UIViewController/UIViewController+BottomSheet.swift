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
    func applyBottomSheetDetents(with scrollView: UIScrollView? = nil) -> AnyCancellable? {
#if !os(visionOS)
        guard let sheet = sheetPresentationController else { return nil }
        sheet.prefersGrabberVisible = true

        /// If UIScrollView is not presented,
        /// or iOS 16 is not available, than set default detents
        guard let scrollView,
              #available(iOS 16.0, *)
        else {
            sheet.detents = [.medium(), .large()]
            return nil
        }

        sheet.detents = [.custom(resolver: { [unowned self] context in
            let height = scrollView.contentSize.height + view.layoutMargins.top
            return min(height, context.maximumDetentValue)
        })]

        return scrollView.publisher(for: \.contentSize).sink(receiveValue: { _ in
            sheet.animateChanges {
                sheet.invalidateDetents()
            }
        })
#else
        return nil
#endif
    }

}
