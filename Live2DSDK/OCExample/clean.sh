rm -fr Podfile.lock Pods                                                                        
pod cache clean --all
pod install
open OCExample.xcworkspace