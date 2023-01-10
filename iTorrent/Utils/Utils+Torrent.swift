//
//  Utils+Torrent.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 10.01.2023.
//  Copyright © 2023  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif


extension Utils {
    public static func checkFolderExist(path: String) {
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }

    public static func getWiFiAddress() -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        guard let firstAddr = ifaddr else {
            return nil
        }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) { // } || addrFamily == UInt8(AF_INET6) {
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }

    public static func interfaceNames() -> [String] {
        let MAX_INTERFACES = 128

        var interfaceNames = [String]()
        let interfaceNamePtr = UnsafeMutablePointer<Int8>.allocate(capacity: Int(IF_NAMESIZE))
        for interfaceIndex in 1 ... MAX_INTERFACES {
            if if_indextoname(UInt32(interfaceIndex), interfaceNamePtr) != nil {
                let interfaceName = String(cString: interfaceNamePtr)
                interfaceNames.append(interfaceName)
            } else {
                break
            }
        }

        interfaceNamePtr.deallocate()
        return interfaceNames
    }

    public static func getFileByName(_ array: [FileModel], file: FileModel) -> FileModel? {
        for afile in array {
            if afile.name == file.name {
                return afile
            }
        }
        return nil
    }
}
