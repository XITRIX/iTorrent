//#!/usr/bin/swiftc -parse-as-library

import Foundation

let rootUrl = "https://raw.githubusercontent.com/XITRIX/iTorrent-v2/main"

// MARK: - AltStore Models
struct AltStoreAppPermissionModel: Codable {
    var entitlements: [String] = ["com.apple.security.application-groups"]
    var privacy: [String: String] = [:]
}

struct AltStoreAppVersionModel: Codable {
    var version: String
    var date: String
    var size: UInt
    var downloadURL: String
    var localizedDescription: String?
    var minOSVersion: String? = "16.0"
}

struct AltStoreAppModel: Codable {
    var name: String = "iTorrent"
    var bundleIdentifier: String = "com.xitrix.iTorrent2"
    var developerName: String = "XITRIX"
    var subtitle: String?
    var localizedDescription: String = "Torrent client for iOS"
    var iconURL: String = "\(rootUrl)/iTorrent/Core/Assets/Assets.xcassets/AppIcon.appiconset/Untitled.png"
    var tintColor: String? = "#D03E43"
    var category: String? = "utilities"
    var screenshots: [String]?
    var versions: [AltStoreAppVersionModel]
    var appPermissions: AltStoreAppPermissionModel = .init()
}

struct AltStoreSourceModel: Codable {
    var name: String = "iTorrent Source"
    var subtitle: String?
    var description: String? = "Official source for iTorrent app"
    var iconURL: String? = "\(rootUrl)/iTorrent/Core/Assets/Assets.xcassets/AppIcon.appiconset/Untitled.png"
    var headerURL: String? = "\(rootUrl)/iTorrent/Core/Assets/Assets.xcassets/AppIcon.appiconset/Untitled.png"
    var website: String? = "https://github.com/XITRIX/iTorrent"
    var tintColor: String? = "#D03E43"
    var featuredApps: [String] = ["com.xitrix.iTorrent2"]
    var apps: [AltStoreAppModel]
}

// MARK: - GitHub Models
struct GitHubAssetModel: Codable {
    var name: String
    var browserDownloadUrl: String
    var size: UInt
}

struct GitHubReleaseModel: Codable {
    var name: String
    var publishedAt: String
    var assets: [GitHubAssetModel]
}

// MARK: - App
@main
struct AltServerGenerator {
    static func main() async throws {
        let url = "https://api.github.com/repos/XITRIX/iTorrent-v2/releases"
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let releases = try decoder.decode([GitHubReleaseModel].self, from: data)

//        print(releases)

        let versions = releases.compactMap { release -> AltStoreAppVersionModel? in
            guard let ipaAsset = release.assets.first(where: { $0.name == "iTorrent.ipa" })
            else { return nil }

            return AltStoreAppVersionModel(version: release.name, date: release.publishedAt, size: ipaAsset.size, downloadURL: ipaAsset.browserDownloadUrl)
        }

        let model = AltStoreSourceModel(apps: [
            .init(versions: versions)
        ])

        let sourceJsonData = try JSONEncoder().encode(model)
        let sourceJson = String(data: sourceJsonData, encoding: .utf8)!
        print(sourceJson)
    }
}
