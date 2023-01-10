#plugin 'cocoapods-binary'

platform :ios, '11.0'
#enable_bitcode_for_prebuilt_frameworks!
#keep_source_code_for_prebuilt_frameworks!
#all_binary!

target 'iTorrent' do
  use_frameworks!
  pod 'MarqueeLabel'
  pod "GCDWebServer/WebUploader", "~> 3.0"
  pod "GCDWebServer/WebDAV", "~> 3.0"
  pod 'DeepDiff'
  pod "SwiftyXMLParser", :git => 'https://github.com/yahoojapan/SwiftyXMLParser.git'
  pod 'Google-Mobile-Ads-SDK'
  pod 'Firebase/Core'
  pod 'Firebase/Performance'
  pod 'FirebaseCrashlytics'
  pod 'AppCenter'
  pod 'Bond'
end

#target 'iTorrent-ProgressWidgetExtension' do
#  use_frameworks!
#end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == "Pods-[Name of Project]"
      puts "Updating #{target.name} to exclude Crashlytics/Fabric"
      target.build_configurations.each do |config|
       	xcconfig_path = config.base_configuration_reference.real_path
        xcconfig = File.read(xcconfig_path)
        xcconfig.sub!('-framework "Crashlytics"', '')
        xcconfig.sub!('-framework "Fabric"', '')
        new_xcconfig = xcconfig + 'OTHER_LDFLAGS[sdk=iphone*] = -framework "Crashlytics" -framework "Fabric"'
        File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
      end
    end	
  end

  #fix MarqueeLabel IBDesignable error
  installer.pods_project.build_configurations.each do |config|
    config.build_settings.delete('CODE_SIGNING_ALLOWED')
    config.build_settings.delete('CODE_SIGNING_REQUIRED')
  end
end

