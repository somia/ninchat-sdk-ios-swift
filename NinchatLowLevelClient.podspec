# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatLowLevelClient"
  s.version      = "0.3.10"
  s.summary      = "Low-level communications library for Ninchat messaging."
  s.description  = "For providing low-level communications using Ninchat messaging."
  s.homepage     = "https://ninchat.com/"
  s.license      = { :type => "BSD", :file => "LICENSE.md" }
  s.author       = { "Hassan Shahbazi" => "hassan@ninchat.com" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios-swift.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "13.0"
  s.vendored_frameworks = "Frameworks/NinchatLowLevelClient.xcframework"
  s.module_name = "NinchatLowLevelClient"
  s.static_framework = true

end

