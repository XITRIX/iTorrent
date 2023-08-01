<img align="left" width="100" height="100" src="https://user-images.githubusercontent.com/9553519/80646366-3d271680-8a75-11ea-8b60-9c5edd4ffd60.png">

# iTorrent - iOS Torrent client App
[**Readme in Spanish**](README.es.md)

![](https://img.shields.io/badge/iOS-9.3+-blue.svg)
![](https://app.bitrise.io/app/26ce0756a727335c/status.svg?token=BLhjBICoPvmOtO1nzIVMYQ&branch=master)
[![](https://build.appcenter.ms/v0.1/apps/a9efbde4-560e-438a-a178-b17563f9c2da/branches/Dev/badge)](https://install.appcenter.ms/users/x1trix/apps/itorrent/distribution_groups/public)

## Screenshots
<details>
<summary>iPhone Screenshots</summary>
  
![iPhone screenshots](https://user-images.githubusercontent.com/9553519/80644526-7316cb80-8a72-11ea-95b5-e63531d81f35.png)

</details>
<details>
<summary>iPad Screenshots</summary>

![iPad screenshots](https://user-images.githubusercontent.com/9553519/80646848-27feb780-8a76-11ea-8c91-f76d25c0b862.png)

</details>

## Download

**Latest stable build:** ([GitHub Release](https://github.com/XITRIX/iTorrent/releases/latest))

**Latest dev build:** ([AppCenter](https://install.appcenter.ms/users/x1trix/apps/itorrent/distribution_groups/public)) 

## Info

It is an ordinary torrent client for iOS with Files app support.

What can this app do:
- Download in the background
- Sequential download (use VLC to watch films while loading)
- Add torrent files from Share menu (Safari and other apps)
- Add magnet links directly from Safari
- Store files in Files app (iOS 11+)
- File sharing directly from app
- Download torrent by link
- Download torrent by magnet
- Send notification on torrent downloaded
- WebDav Server
- Select files to download or not
- Change UI to dark theme
- RSS Feed
- ??? 

## Localization

Now iTorrent supports the following languages:
- English
- Russian
- Turkish
- Spanish

If you are fluent in the languages not listed above and want to help with translation, you are welcome!

## Build

To build that project you need to have Cocoapods installed

Steps:
- cd terminal to project's folder "cd /home/user/iTorrent"
- Build pods "pod install"
- Open .xcworkspace and build it
- Profit

## Libraries used

- [LibTorrent](https://github.com/arvidn/libtorrent)
- [BackgroundTask](https://github.com/yarodevuci/backgroundTask)
- [SwiftyXMLParser](https://github.com/yahoojapan/SwiftyXMLParser)
- [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel)
- [DeepDiff](https://github.com/onmyway133/DeepDiff)

## Donate for donuts

- [Patreon](https://www.patreon.com/xitrix)
- [PayPal](https://paypal.me/xitrix)

## Important information

This app using Firebase Analytics and so it collects next information from your device:
- The country of your internet provider
- Time of app's working session

All this data presents as statistic, and cannot be used to get someone's personal information

Also this app using Firebase Crashlytics, which collects the next information when application crashes:
- Model of your device (IPhone X or IPad Pro (10.5 inch) for example)
- Device orientation
- Free space on RAM and ROM
- IOS version
- Time of crash
- Detailed log of the thread where the stuck happens

All this information is using for bug fixing and improving the quality of this app

More information you can find on [Firebase website](https://firebase.google.com)

## License

Copyright (c) 2019 XITRIX (Vinogradov Daniil)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

