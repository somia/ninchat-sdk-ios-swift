# coding: utf-8

Pod::Spec.new do |s|
  s.name         = 'JitsiMeetSDK'
  s.version      = '0.6.0'
  s.summary      = 'Jitsi Meet iOS SDK (forked from 7.0.1)'
  s.description  = 'Jitsi Meet is a WebRTC compatible, free and Open Source video conferencing system that provides browsers and mobile applications with Real Time Communications capabilities.'
  s.homepage     = 'https://github.com/jitsi/jitsi-meet-ios-sdk-releases'
  s.license      = 'Apache 2'
  s.authors      = 'The Jitsi Meet project authors'
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios-swift.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "13.0"
  s.vendored_frameworks = "Frameworks/JitsiMeetSDK.xcframework"

  s.dependency 'Giphy', '2.1.20'
  s.dependency 'JitsiWebRTC', '~> 106.0'
end
