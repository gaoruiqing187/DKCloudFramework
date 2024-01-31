#
# Be sure to run `pod lib lint DKCloudFramework.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'DKCloudFramework'
  s.version          = '1.0.11'
  s.summary          = 'A short description of DKCloudFramework.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/gaoruiqing187/DKCloudFramework'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'gaoruiqing187' => '494063010@qq.com' }
  s.source           = { :git => 'git@github.com:gaoruiqing187/DKCloudFramework.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'DKCloudFramework/Classes/**/*'
  s.pod_target_xcconfig = {
      'VALID_ARCHS' => 'arm64 x86_64'
  }
  # s.resource_bundles = {
  #   'DKCloudFramework' => ['DKCloudFramework/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Starscream', '4.0.4'
  s.dependency 'linphone-sdk-novideo', '5.2.112'
end
