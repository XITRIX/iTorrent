// #!/usr/bin/swiftc -parse-as-library

import Foundation

let rootUrl = "https://raw.githubusercontent.com/XITRIX/iTorrent-v2/main"
let rootDistrUrl = "https://raw.githubusercontent.com/XITRIX/xitrix.github.io/master"

let _iphoneStandardScreenshots: [String] = [
    "\(rootDistrUrl)/screenshots/1.PNG",
    "\(rootDistrUrl)/screenshots/2.PNG",
    "\(rootDistrUrl)/screenshots/3.PNG",
    "\(rootDistrUrl)/screenshots/4.PNG",
]

let _iphoneEdgeToEdgeScreenshots: [String] = [
    "\(rootDistrUrl)/screenshots/sidestore/1.png",
    "\(rootDistrUrl)/screenshots/sidestore/2.png",
    "\(rootDistrUrl)/screenshots/sidestore/3.png",
    "\(rootDistrUrl)/screenshots/sidestore/4.png",
    "\(rootDistrUrl)/screenshots/sidestore/5.png",
]

// MARK: - AltStore Models
struct SideStoreScreenshotsModel: Codable {
    var iphoneStandard: [String]? = _iphoneStandardScreenshots
    var iphoneEdgeToEdge: [String]? = _iphoneEdgeToEdgeScreenshots
    var ipad: [String]?

    enum CodingKeys: String, CodingKey {
        case iphoneStandard = "iphone-standard"
        case iphoneEdgeToEdge = "iphone-edgeToEdge"
        case ipad
    }
}

struct AltStoreAppPermissionModel: Codable {
    var entitlements: [String] = ["com.apple.security.application-groups"]
    var privacy: [String: String] = [
        :
        // "NSLocationWhenInUseUsageDescription": "More robust alternative to hold app working in background which requires additional permission, enables Dynamic Island progress extension",
        // "NSLocationAlwaysAndWhenInUseUsageDescription": "This additional permission allows to hide location indicator from status bar during background downloading",
    ]
}

struct SideStoreAppPermissionModel: Codable {
    var type: String
    var usageDescription: String
}

struct AltStoreAppVersionModel: Codable {
    var version: String
    var buildVersion: String? = "1"
    var date: String
    var size: UInt
    var downloadURL: String
    var localizedDescription: String?
    var minOSVersion: String? = "16.0"
}

struct AltStorePatreonModel: Codable {
    var pledge: Double
    var currency: String?
}

struct AltStoreAppModel: Codable {
    var name: String = "iTorrent"
    var bundleIdentifier: String = "com.xitrix.iTorrent2"
    var developerName: String = "XITRIX"
    var marketplaceID: String?
    var subtitle: String?
    var localizedDescription: String =
        """
        It is an ordinary torrent client for iOS with Files app support and much more.

        What can this app do:

        • Download in the background
        • Sequential download (use VLC to watch films while loading)
        • Add torrent files from Share menu (Safari and other apps)
        • Add magnet links directly from Safari
        • Store files in Files app
        • File sharing directly from app
        • Download torrent by url
        • Download torrent by magnet
        • Show progress in Dynamic Island
        • Send notification on torrent downloaded
        • Web/WebDav Server
        • Select files download priority
        • Change UI to dark theme
        • Color personalization
        • RSS Feed
        • ???
        """
    var downloadURL: String
    var iconURL: String = "\(rootDistrUrl)/icon.png"
    var tintColor: String? = "#F19E69"
    var category: String? = "utilities"
    var screenshots: [String]? = _iphoneStandardScreenshots
    var screenshotURLs: [String]? = _iphoneEdgeToEdgeScreenshots
    var versions: [AltStoreAppVersionModel]
    var appPermissions: AltStoreAppPermissionModel = .init()
    var permissions: [SideStoreAppPermissionModel] = [
        .init(type: "network", usageDescription: "Needs to download torrents"),
        .init(type: "background-audio", usageDescription: "Needs to hold app working in background"),
        .init(type: "location", usageDescription: "More robust alternative to hold app working in background which requires additional permission"),
    ]
    var patreon: AltStorePatreonModel?
    var beta: Bool?
}

struct AltStoreSourceModel: Codable {
    var name: String = "iTorrent Source"
    var identifier: String = "com.xitrix.itorrent"
    var subtitle: String? = "Torrent client for iOS"
    var description: String? = "Official source for iTorrent app"
    var iconURL: String? = "\(rootDistrUrl)/sourceIcon.png"
    var headerURL: String? = "\(rootDistrUrl)/sourceIcon.png"
    var website: String? = "https://github.com/XITRIX/iTorrent"
    var patreonURL: String? = "https://www.patreon.com/xitrix"
    var tintColor: String? = "#F19E69"
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
enum AltServerGenerator {
    static func main() async throws {
        let withNotarization = CommandLine.arguments.contains(where: { $0 == "eu" })

        let url = "https://api.github.com/repos/XITRIX/iTorrent-v2/releases"
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let releases = try decoder.decode([GitHubReleaseModel].self, from: data)

//        print(releases)

        let versions = releases.compactMap { release -> AltStoreAppVersionModel? in
            guard let ipaAsset = release.assets.first(where: { $0.name == "iTorrent.ipa" })
            else { return nil }

            let versionParts = release.name.replacingOccurrences(of: "v", with: "").split(separator: "-")
            let version = versionParts.first.map { String($0) } ?? "1.0.0"
            var buildVersion: String?
            if versionParts.count > 1 {
                buildVersion = versionParts.last.map { String($0) }
            }

            return AltStoreAppVersionModel(
                version: version,
                buildVersion: buildVersion,
                date: release.publishedAt,
                size: ipaAsset.size,
                downloadURL: ipaAsset.browserDownloadUrl
            )
        }

        let model = AltStoreSourceModel(
            tintColor: "D03E43",
            apps: [
                AltStoreAppModel(
                    marketplaceID: withNotarization ? "6499499971" : nil,
                    downloadURL: versions.first?.downloadURL ?? "",
                    versions: versions,
                    patreon: .init(pledge: 2),
                    beta: true
                ),
            ]
        )

        let sourceJsonData = try JSONEncoder().encode(model)
        let sourceJson = String(data: sourceJsonData, encoding: .utf8)!
        print(sourceJson)
    }
}
