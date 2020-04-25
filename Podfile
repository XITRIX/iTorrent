# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'iTorrent' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for iTorrent
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

