#
# Be sure to run `pod lib lint FBPod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FBPod'
  s.version          = '0.1.0'
  s.summary          = 'A short description of FBPod.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Simple FB plugin for personal use
                       DESC

  s.homepage         = 'https://github.com/tthufo/FBPod'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tthufo' => 'tthufo@gmail.com' }
  s.source           = { :git => 'https://github.com/tthufo/FBPod.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  
  s.source_files = 'FBPod/Classes'
  
  s.public_header_files = 'FBPod/Classes/*.h'
  
  s.dependency 'FBSDKCoreKit', '~> 4.4'
  s.dependency 'FBSDKLoginKit', '~> 4.4'
  s.dependency 'FBSDKShareKit', '~> 4.4'
  s.dependency 'SVProgressHUD'
end
