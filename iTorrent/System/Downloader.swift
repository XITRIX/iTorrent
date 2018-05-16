//
//  Downloader.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

class Downloader {
    class func load(url: URL, to localUrl: URL, completion: @escaping () -> (), errorAction: @escaping () -> () = {}) {
        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
            if error != nil {
                print("Error downloading from \(url)")
                errorAction()
            } else {
                // Do something with your file in location
                try! FileManager.default.moveItem(at: location!, to: localUrl)
                completion()
            }
        }
        task.resume()
    }
}
