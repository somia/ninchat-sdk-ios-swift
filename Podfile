platform :ios, '10.0'
use_frameworks!

source 'https://cdn.cocoapods.org/'
source 'https://github.com/somia/ninchat-podspecs.git'

def all_pods
    pod 'AnyCodable', :inhibit_warnings => true
    pod 'AutoLayoutSwift'
    pod 'NinchatLowLevelClient', '~> 0.0.40', :inhibit_warnings => true
    pod 'NinchatSDK', :git => 'https://github.com/somia/ninchat-sdk-ios', :branch => 'swift'
end

target 'NinchatSDKSwift' do
    all_pods
end

target 'NinchatSDKSwiftTests' do
    all_pods
end

target 'NinchatSDKSwiftServerTests' do
  all_pods
end