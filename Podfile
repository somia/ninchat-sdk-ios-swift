platform :ios, '10.0'
inhibit_all_warnings!
use_frameworks!

source 'https://cdn.cocoapods.org/'
source 'https://github.com/somia/ninchat-podspecs.git'

def libraries
  pod 'AnyCodable-FlightSchool', '~> 0.2.3'
  pod 'AutoLayoutSwift', '4.0.0'
  pod 'NinchatLowLevelClient', '~> 0.3.10'
  pod 'NinchatWebRTC', '~> 0.6.0'
end

target 'NinchatSDKSwift' do
  libraries

  target 'NinchatSDKSwiftTests' do
    inherit! :search_paths
    libraries
  end

  target 'NinchatSDKSwiftServerTests' do
    inherit! :search_paths
    libraries
  end
end



post_install do |pi|
    pi.pods_project.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10'
    end
    pi.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      end
    end
end

