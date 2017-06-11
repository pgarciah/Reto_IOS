//
//  AppDelegate.h
//  Reto
//
//  Created by Pablo García on 9/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSMutableDictionary *icons;
+ (AppDelegate *)sharedAppDelegate;

@end

