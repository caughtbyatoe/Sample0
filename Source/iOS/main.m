// Copyright (c) 2021 caughtbyatoe
//
//  main.m
//  Sample0_iOS
//
//

#include <UIKit/UIKit.h>
#include "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
