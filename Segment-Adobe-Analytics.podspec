Pod::Spec.new do |s|
  s.name             = 'Segment-Adobe-Analytics'
  s.version          = '1.0.0-beta'
  s.summary          = 'Adobe-Analytics Integration for Segment\'s analytics-ios library.'
  s.description      = <<-DESC

  Analytics for iOS provides a single API that lets you
    integrate with over 100s of tools.
    This is the Optimizely X integration for the iOS library.
                       DESC

  s.homepage         = 'http://segment.com/'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Segment' => 'friends@segment.com' }
  s.source           = { :git => 'https://github.com/segment-integrations/analytics-ios-integration-Adobe-Analytics.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/segment'

  s.ios.deployment_target = '8.0'
  s.source_files = 'Pod/Classes/**/*'

  s.dependency 'Analytics', '~> 3.5'
  s.dependency 'AdobeMobileSDK'
  s.dependency 'AdobeVideoHeartbeatSDK'
end
