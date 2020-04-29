//
//  FileManagerExtensions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 27.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

extension FileManager {
    func clearTmpDirectory() {
        do {
            let tmpDirectory = try contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach {[unowned self] file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try self.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }
}
