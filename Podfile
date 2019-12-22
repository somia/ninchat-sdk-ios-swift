platform :ios, '9.0'
use_frameworks!

source 'https://cdn.cocoapods.org/'
source 'https://github.com/somia/ninchat-podspecs.git'

def all_pods
    pod 'NinchatSDK', :git => 'https://github.com/somia/ninchat-sdk-ios', :branch => 'swift'
    #pod 'NinchatSDK', :path => '../ninchat-sdk-ios'
end

target 'NinchatSDKSwift' do
    all_pods
end

target 'NinchatSDKSwiftTests' do
    all_pods
end

