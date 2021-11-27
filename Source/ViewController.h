// Copyright (c) 2021 caughtbyatoe
//
//  ViewController.h
//  Sample0
//
//

#include <TargetConditionals.h>

#if TARGET_OS_OSX
#include <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@end

#else
#include <UIKit/UIKit.h>

@interface ViewController : UIViewController
@end

#endif
