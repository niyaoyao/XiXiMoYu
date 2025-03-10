Pod::Spec.new do |s|
  s.name             = 'Live2DSDK'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Live2DSDK.'
  s.description      = <<-DESC
    TODO: Add long description of the pod here.
  DESC
  s.homepage         = 'https://github.com/NY/Live2DSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NY' => 'nycode.jn@gmail.com' }
  s.source           = { :git => 'https://github.com/NY/Live2DSDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'

  s.subspec 'Core' do |sp|
    sp.source_files = 'Live2DSDK/Classes/Framework/**/*.{h,hpp,c,cpp,metal,tpp,m,mm}'
    sp.libraries = 'c++'
    sp.requires_arc = false
    sp.ios.vendored_library = 'Live2DSDK/Classes/Framework/Library/libLive2DCubismCore.a'
  end

  s.subspec 'AppSource' do |sp|
    sp.source_files = 'Live2DSDK/Classes/App/**/*.{h,metal,m,mm}'
    sp.public_header_files = 'Live2DSDK/Classes/App/**/*.{h,hpp}'
    sp.libraries = 'c++'
    sp.requires_arc = false
  end

  # 在此处定义资源
  s.resources =  ['Live2DSDK/Assets/Live2DModels.bundle']

  s.frameworks = 'UIKit', 'CoreGraphics', 'Foundation', 'MetalKit', 'Metal', 'QuartzCore'
  # Link to the C++ standard library
  s.libraries = 'c++'

  # Ensure C++11 or later is used
  s.pod_target_xcconfig = {
    'OTHER_CPLUSPLUSFLAGS' => '-std=c++11',            # Ensure C++11 is used
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',           # Specify C++11 language standard
    'OTHER_CFLAGS' => '-DDEBUG',                        # Optional: Set any preprocessor flags
  }
end
