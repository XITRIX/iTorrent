[AltStore Button]: https://img.shields.io/badge/Download-AltStore-green?style=flat
[AltStore Link]: https://intradeus.github.io/http-protocol-redirector?r=altstore://source?url=https://xitrix.github.io/iTorrent/AltStore.json 'Download with AltStore.'

[SideStore Button]: https://img.shields.io/badge/Download-SideStore-purple?style=flat
[SideStore Link]: https://intradeus.github.io/http-protocol-redirector?r=sidestore://source?url=https://xitrix.github.io/iTorrent/AltStore.json 'Download with SideStore.'

[Jailbreak Button]: https://img.shields.io/badge/Download-Jailbreak-red?style=flat
[Jailbreak Link]: https://intradeus.github.io/http-protocol-redirector?r=itms-services://?action=download-manifest&url=https://github.com/XITRIX/iTorrent/releases/latest/download/manifest.plist 'Download with Jailbreak.'

[GitHub Button]: https://img.shields.io/badge/Download-GitHub-black?style=flat
[GitHub Link]: https://github.com/XITRIX/iTorrent/releases 'Download from GitHub.'

<img align="left" width="100" height="100" src="https://github.com/user-attachments/assets/0faf6075-273b-4b74-92d6-dccab7f4b964">


# iTorrent - iOS Torrent client App
[![AltStore Button]][AltStore Link]
[![SideStore Button]][SideStore Link]
[![GitHub Button]][GitHub Link]
[![Jailbreak Button]][Jailbreak Link]
![](https://img.shields.io/badge/iOS-16.0+-blue.svg)


> [!WARNING]
> iTorrent 2.0 app is in beta preview state, expect to see some bugs and be ready report about them.


## Screenshots
<details>
<summary>iPhone Screenshots</summary>
  <p float="left">
  <img width="250" src="https://github.com/user-attachments/assets/73256524-4861-4b8f-afba-5bd657badb2f" />
  <img width="250" src="https://github.com/user-attachments/assets/9ac2c682-a3b4-4498-8daa-6c5c6f742946" />
  <img width="250" src="https://github.com/user-attachments/assets/c2f06516-862a-47b5-b69b-aed4f6043aae" />
  <img width="250" src="https://github.com/user-attachments/assets/c7dff083-4fe7-4440-9961-9eb472e22142" />
  <img width="250" src="https://github.com/user-attachments/assets/be15d663-0d5b-40ed-aa6c-1f3eb9e00a1e" />
  <img width="250" src="https://github.com/user-attachments/assets/20aac5d9-8746-4357-b1d8-7aa15bac2747" />
  </p>
</details>

<details>
<summary>iPad Screenshots</summary>
  <p float="left">
  <img width="378" src="https://github.com/user-attachments/assets/5152a496-6949-4c33-a0b9-4ec9e1ea32e8" />
  <img width="378" src="https://github.com/user-attachments/assets/5af9eb69-4eb4-419c-bcae-2b42f5553eea" />
  </p>
</details>

## Info

It is an ordinary torrent client for iOS with Files app support.

What can this app do:
- Download in the background
- Live Activity and Dynamic Island progress widget
- Sequential download (use VLC to watch films while loading)
- Add torrent files from Share menu (Safari and other apps)
- Add magnet links directly from Safari
- Store files in Files app
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
- Spanish
- Simplified Chinese

If you are fluent in the languages not listed above and want to help with translation, you are welcome!

## Libraries used

- [LibTorrent](https://github.com/arvidn/libtorrent)
- [OpenSSL](https://github.com/krzyzanowskim/OpenSSL)
- [MvvmFoundation](https://github.com/XITRIX/MVVMFoundation)
- [CombineCocoa](https://github.com/XITRIX/CombineCocoa)
- [SWXMLHash](https://github.com/drmohundro/SWXMLHash)
- [MarqueeText](https://github.com/joekndy/MarqueeText)
- [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel)
- [GCDWebServer](https://github.com/XITRIX/GCDWebServer)
- [Firebase](https://github.com/firebase/firebase-ios-sdk)

## Donate for donuts

- [Patreon](https://www.patreon.com/xitrix)
- [PayPal](https://paypal.me/x1trix)

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

Copyright (c) 2024 XITRIX (Vinogradov Daniil)

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
