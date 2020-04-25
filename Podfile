#plugin 'cocoapods-binary'

platform :ios, '9.3'
#enable_bitcode_for_prebuilt_frameworks!
#keep_source_code_for_prebuilt_frameworks!
#all_binary!

target 'iTorrent' do
  use_frameworks!
  pod 'Firebase/Core'
  pod 'Firebase/Performance'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'MarqueeLabel'
  pod 'Google-Mobile-Ads-SDK'
  pod "GCDWebServer/WebUploader", "~> 3.0"
  pod "GCDWebServer/WebDAV", "~> 3.0"
  pod 'AppCenter'
end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings['ENABLE_BITCODE'] = 'YES'
		end
	end

	#fix MarqueeLabel IBDesignable error
	installer.pods_project.build_configurations.each do |config|
    		config.build_settings.delete('CODE_SIGNING_ALLOWED')
    		config.build_settings.delete('CODE_SIGNING_REQUIRED')
  	end
end

