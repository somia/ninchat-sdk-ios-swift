# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatSDKSwift"
  s.version      = "0.5.7"
  s.summary      = "iOS SDK for Ninchat, Swift version"
  s.description  = "For building iOS applications using Ninchat messaging."
  s.homepage     = "https://ninchat.com/"
  s.license      = { :type => "Ninchat", :file => "LICENSE.md" }
  s.author       = { "Hassan Shahbazi" => "hassan@ninchat.com" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios-swift.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "10.0"

  # Handle the SDK itself as a subspec with dependencies to the frameworks
  s.subspec "SDKSwift" do |ss|
    ss.source_files  = "NinchatSDKSwift/**/*.{swift}"
    ss.resource_bundles = {
        "NinchatSwiftSDKUI" => "NinchatSDKSwift/**/*.{storyboard,xib,xcassets,strings,ttf}"
    }
  end

  # The SDK is our main spec
  s.default_subspec = "SDKSwift"

  # Our dependency (NinchatLowLevel) is a static library, so we must also be
  s.static_framework = true

  # Due to gomobile bind not supporting bitcode we must switch it off - for
  # the pod as well as the user target (app using the SDK). This is unfortunate,
  # but hopefully support will be there soon.
  # In addition we must suppress 'illegal text relocation' error for i386 platform
  s.pod_target_xcconfig = {
    "OTHER_LDFLAGS[arch=i386]" => "-Wl,-read_only_relocs,suppress -lstdc++",
    "ENABLE_BITCODE" => "NO",
    "SWIFT_SUPPRESS_WARNINGS" => "YES",
    "ONLY_ACTIVE_ARCHS" => "NO"
  }
  s.user_target_xcconfig = {
      "ENABLE_BITCODE" => "NO"
  }

  # Cocoapods dependencies
  s.dependency "GoogleWebRTC"
  s.dependency 'AnyCodable-FlightSchool', '~> 0.2.3'
  s.dependency "AutoLayoutSwift", "4.0.0"
  s.dependency "NinchatLowLevelClient", "~> 0.3.10"

  s.module_name = "NinchatSDKSwift"
end
