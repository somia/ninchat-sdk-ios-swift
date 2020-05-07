platform :ios, '10.0'
inhibit_all_warnings!
use_frameworks!

source 'https://cdn.cocoapods.org/'
source 'https://github.com/somia/ninchat-podspecs.git'

def libraries
  pod 'AnyCodable-FlightSchool', '~> 0.2.3'
  pod 'AutoLayoutSwift', '4.0.0'
  pod 'NinchatLowLevelClient', '~> 0.0.40'
  pod 'GoogleWebRTC'
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



