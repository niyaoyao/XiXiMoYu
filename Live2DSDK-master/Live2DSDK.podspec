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

  s.homepage         = 'https://github.com/niyaoyao/Live2DSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wudijimao' => 'wuximiao@rd.netease.com' }
  s.source           = { :git => 'https://github.com/niyaoyao/Live2DSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.subspec 'Core' do |sp|
    sp.source_files = 'Live2DSDK/CubismSdkForNative/Core/include/**/*.{h,hpp,c,cpp,m,mm}'
    sp.ios.vendored_library = 'Live2DSDK/CubismSdkForNative/Core/lib/ios/Release-iphoneos/libLive2DCubismCore.a'
    sp.libraries = 'c++'
  end
  
  s.subspec 'FrameworkCore' do |sp|
#    sp.public_header_files = 'Live2DSDK/CubismSdkForNative/Framework/src/Type/*.{h,hpp}',
#                             'Live2DSDK/CubismSdkForNative/Framework/src/Id/*.{h,hpp}'
    sp.private_header_files = 'Live2DSDK/CubismSdkForNative/**/*.{h,hpp}'
    sp.source_files = 'Live2DSDK/CubismSdkForNative/Framework/src/**/*.{h,hpp,c,cpp,m,mm}'
    sp.exclude_files = "Live2DSDK/CubismSdkForNative/Framework/src/Rendering/**/*"
#    sp.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '"$(SRCROOT)/Live2DSDK/CubismSdkForNative/Framework/src/"' }
    sp.requires_arc = false
    sp.libraries = 'c++'
  end
  
  s.subspec 'FrameworkMetal' do |sp|
#    sp.public_header_files = 'Live2DSDK/CubismSdkForNative/Framework/src/Rendering/Metal/**/*.{h,hpp}'
    sp.private_header_files = 'Live2DSDK/CubismSdkForNative/**/*.{h,hpp}'
    sp.source_files = 'Live2DSDK/CubismSdkForNative/Framework/src/Rendering/Metal/**/*.{h,hpp,c,cpp,m,mm}',
    "Live2DSDK/CubismSdkForNative/Framework/src/Rendering/*"
    sp.requires_arc = false
    sp.libraries = 'c++'
  end
  
  s.subspec 'AppMetal' do |sp|
    sp.private_header_files = 'Live2DSDK/CubismSdkForNative/**/*.{h,hpp}'
    sp.source_files = "Live2DSDK/CubismSdkForNative/Samples/Metal/Demo/proj.ios.cmake/src/**/*.{h,hpp,c,cpp,m,mm}",
                      "Live2DSDK/CubismSdkForNative/Samples/Metal/thirdParty/stb/stb_image.h"
    sp.exclude_files = "Live2DSDK/CubismSdkForNative/Samples/Metal/Demo/proj.ios.cmake/src/AppDelegate.*",
    "Live2DSDK/CubismSdkForNative/Samples/Metal/Demo/proj.ios.cmake/src/ViewController.*",
    "Live2DSDK/CubismSdkForNative/Samples/Metal/Demo/proj.ios.cmake/src/main.*"
    sp.requires_arc = false
    sp.libraries = 'c++'
  end
  
  # s.resource_bundles = {
  #   'Live2DSDK' => ['Live2DSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
