# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatWebRTC"
  s.version      = "0.6.0"
  s.summary      = "Manually built version of Google WebRTC"
  s.description  = "Manually built WebRTC framework as the iOS pod is not updated by Google Anymore"
  s.homepage     = "https://ninchat.com/"
  s.license      = { :type => "BSD", :file => "LICENSE.md" }
  s.author       = { "Hassan Shahbazi" => "hassan@ninchat.com" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios-swift.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "10.0"
  s.vendored_frameworks = "Frameworks/NinchatWebRTC.framework"
  s.module_name = "NinchatWebRTC"
  s.static_framework = true

end

