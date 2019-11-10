//
//  Section.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10.11.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

struct Section {
    var rowModels: [CellModelProtocol] = []
    var header: String = ""
    var footer: String = ""
    var headerFunc: (() -> (String))? = nil
    var footerFunc: (() -> (String))? = nil
}
