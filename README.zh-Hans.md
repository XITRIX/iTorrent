<img align="left" width="100" height="100" src="https://user-images.githubusercontent.com/9553519/80646366-3d271680-8a75-11ea-8b60-9c5edd4ffd60.png">

# iTorrent - iOS Torrent 客户端APP

![](https://img.shields.io/badge/iOS-9.3+-blue.svg)
![](https://app.bitrise.io/app/26ce0756a727335c/status.svg?token=BLhjBICoPvmOtO1nzIVMYQ&branch=master)
[![](https://build.appcenter.ms/v0.1/apps/a9efbde4-560e-438a-a178-b17563f9c2da/branches/Dev/badge)](https://install.appcenter.ms/users/x1trix/apps/itorrent/distribution_groups/public)

## 截图
<details>
<summary>iPhone 截图</summary>
  
![iPhone 截图](https://user-images.githubusercontent.com/9553519/80644526-7316cb80-8a72-11ea-95b5-e63531d81f35.png)

</details>
<details>
<summary>iPad 截图</summary>

![iPad 截图](https://user-images.githubusercontent.com/9553519/80646848-27feb780-8a76-11ea-8c91-f76d25c0b862.png)

</details>

## 下载

**最新正式版本构建:** ([GitHub Release](https://github.com/XITRIX/iTorrent/releases/latest))

**最新开发版本构建:** ([AppCenter](https://install.appcenter.ms/users/x1trix/apps/itorrent/distribution_groups/public)) 

## 信息

iTorrent是一个普通的Torrent客户端，支持iOS的“文件”APP

这个APP可以做到:
- 在后台下载文件
- 顺序下载（使用VLC边下边看）
- 从“共享”菜单中添加Torrent文件（Safari和其他APP）
- 从Safari直接添加磁力链接
- 将文件储存在“文件”APP中 (iOS 11+)
- 从应用程序直接共享文件
- 使用链接下载Torrent
- 使用磁力链接下载Torrent
- 发送Torrent下载相关的通知
- WebDav服务器
- 选择需要从Torrent下载的文件
- UI可以更改为深色主题
- RSS订阅
- ??? 

## 本地化支持

iTorrent现在支持以下语言：
- English
- Russian
- Turkish
- Spanish
- Simplified Chinese

如果您擅长上面没有列出的语言并希望帮助翻译，欢迎你的贡献！

## 构建

如果要构建这个项目，你需要先安装`Cocoapods`

步骤:
- 使用终端进入到项目文件夹 `cd /home/user/iTorrent`
- 构建pods `pod install`
- 打开`.xcworkspace`并构建他
- 完成

## 使用的库

- [LibTorrent](https://github.com/arvidn/libtorrent)
- [BackgroundTask](https://github.com/yarodevuci/backgroundTask)
- [SwiftyXMLParser](https://github.com/yahoojapan/SwiftyXMLParser)
- [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel)
- [DeepDiff](https://github.com/onmyway133/DeepDiff)

## 捐赠甜甜圈

- [Patreon](https://www.patreon.com/xitrix)
- [PayPal](https://paypal.me/xitrix)

## 重要信息

此APP使用了Firebase Analytics，他会从你的设备中收集以下信息：
- 您的互联网运营商所在的国家/地区
- 此应用程序的工作时间

所有数据均以统计数据的形式呈现，不会用于收集您的个人信息

此APP还使用了Firebase Crashlytics，当APP崩溃时会收集以下信息:
- 您的设备型号 (例如 iPhone X or iPad Pro (10.5 inch))
- 设备方向
- RAM和ROM的剩余可用空间
- iOS版本
- 崩溃时间
- 发生崩溃线程的详细日志

以上所有信息都只用于修复错误并提高该应用程序的稳定性

您可以在 [Firebase website](https://firebase.google.com) 找到更多信息

## 许可

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

