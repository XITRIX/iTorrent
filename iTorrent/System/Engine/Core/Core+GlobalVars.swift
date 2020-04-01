//
//  Core+GlobalVars.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

extension Core {
    public static let rootFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    public static let configFolder = rootFolder + "/_Config"
    public static let fastResumesFolder = configFolder + "/.FastResumes"
}
