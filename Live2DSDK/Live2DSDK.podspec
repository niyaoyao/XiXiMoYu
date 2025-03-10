#
# Be sure to run `pod lib lint Live2DSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Live2DSDK'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Live2DSDK.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/NY/Live2DSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NY' => 'nycode.jn@gmail.com' }
  s.source           = { :git => 'https://github.com/NY/Live2DSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.subspec 'Core' do |sp|
    sp.source_files = 'Live2DSDK/Classes/Framework/**/*.{h,hpp,c,cpp,metal,tpp,m,mm}'
    # sp.private_header_files = 'Live2DSDK/Classes/Framework/**/*.{h,hpp}'

    sp.requires_arc = false
    sp.ios.vendored_library = 'Live2DSDK/Classes/Framework/Library/libLive2DCubismCore.a'
  end

  s.subspec 'AppSource' do |sp|
    sp.source_files = 'Live2DSDK/Classes/App/**/*.{h,metal,m,mm}'
    sp.public_header_files = 'Live2DSDK/Classes/App/**/*.{h,hpp}'

    sp.requires_arc = false
  end
  s.libraries = 'c++'
  # s.resource_bundles = {
  #   'Live2DSDK' => ['Live2DSDK/Assets/**/*.{png,json,moc3,wav,}']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'CoreGraphics', 'Foundation', 'MetalKit', 'Metal', 'QuartzCore'
  # s.dependency 'AFNetworking', '~> 2.3'
    # Enable or disable header maps
  #  s.use_header_maps = false  # Set to true to use header maps

 # Setting different C/C++ flags for Debug and Release configurations
  # s.pod_target_xcconfig = {
  #   'OTHER_CFLAGS' => '-DNDEBUG',         # Release flags
  #   'OTHER_CPLUSPLUSFLAGS' => '-DNDEBUG -std=c++14',         # Release C++ flags
  #   'GCC_PREPROCESSOR_DEFINITIONS' => 'CMAKE_INTDIR="$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)" CSM_TARGET_IPHONE_ES2'
  # }
  
end
