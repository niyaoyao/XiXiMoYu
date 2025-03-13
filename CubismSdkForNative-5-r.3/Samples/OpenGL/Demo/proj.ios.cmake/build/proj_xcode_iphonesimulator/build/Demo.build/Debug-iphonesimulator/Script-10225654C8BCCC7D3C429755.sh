#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Users/niyao/NY/XiXiMoYu/CubismSdkForNative-5-r.3/Samples/OpenGL/Demo/proj.ios.cmake/build/proj_xcode_iphonesimulator
  /usr/local/bin/cmake -E copy_directory /Users/niyao/NY/XiXiMoYu/CubismSdkForNative-5-r.3/Samples/OpenGL/Demo/proj.ios.cmake/../../../../Samples/Resources /Users/niyao/NY/XiXiMoYu/CubismSdkForNative-5-r.3/Samples/OpenGL/Demo/proj.ios.cmake/build/proj_xcode_iphonesimulator/bin/Demo/Debug/Demo.app/Res
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Users/niyao/NY/XiXiMoYu/CubismSdkForNative-5-r.3/Samples/OpenGL/Demo/proj.ios.cmake/build/proj_xcode_iphonesimulator
  /usr/local/bin/cmake -E copy_directory /Users/niyao/NY/XiXiMoYu/CubismSdkForNative-5-r.3/Samples/OpenGL/Demo/proj.ios.cmake/../../../../Samples/Resources /Users/niyao/NY/XiXiMoYu/CubismSdkForNative-5-r.3/Samples/OpenGL/Demo/proj.ios.cmake/build/proj_xcode_iphonesimulator/bin/Demo/Release/Demo.app/Res
fi

