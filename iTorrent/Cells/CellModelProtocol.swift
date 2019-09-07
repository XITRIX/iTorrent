//
//  CellModelProtocol.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import Foundation

protocol CellModelProtocol {
    var reuseCellIdentifier : String { get }
    var hiddenCondition : (()->Bool)? { get }
    var tapAction : (()->())? { get }
}
