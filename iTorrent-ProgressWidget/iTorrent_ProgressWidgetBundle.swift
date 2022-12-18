//
//  iTorrent_ProgressWidgetBundle.swift
//  iTorrent-ProgressWidget
//
//  Created by Даниил Виноградов on 21.11.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
@main
struct iTorrent_ProgressWidgetBundle: WidgetBundle {
    var body: some Widget {
//        iTorrent_ProgressWidget()
        iTorrent_ProgressWidgetLiveActivity()
    }
}
