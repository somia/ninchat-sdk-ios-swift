# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatSDKSwift"
  s.version      = "0.1.1"
  s.summary      = "iOS SDK for Ninchat, Swift version"
  s.description  = "For building iOS applications using Ninchat messaging."
  s.homepage     = "https://ninchat.com/"
  s.license      = { :type => "Ninchat", :file => "LICENSE.md" }
  s.author       = { "Hassan Shahbazi" => "hassan@ninchat.com" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios-swift.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "9.0"

  # Handle the SDK itself as a subspec with dependencies to the frameworks
  s.subspec "SDKSwift" do |ss|
    ss.source_files  = "NinchatSDKSwift/**/*.{swift}"
    ss.resource_bundles = {
        "NinchatSwiftSDKUI" => "NinchatSDKSwift/**/*.{storyboard,xib,xcassets,strings}"
    }
  end

  # The SDK is our main spec
  s.default_subspec = "SDKSwift"

  # Our dependency (NinchatLowLevel) is a static library, so we must also be
  s.static_framework = true

  # Cocoapods dependencies
  s.dependency "NinchatSDK"
  s.dependency "AnyCodable"

  s.module_name = "NinchatSDKSwift"
end
