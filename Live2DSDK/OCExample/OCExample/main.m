//
//  main.m
//  OCExample
//
//  Created by niyao on 3/13/25.
//

#import <UIKit/UIKit.h>
#import "NYAppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([NYAppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
