//
//  UIImageViewAsync.h
//
//  Created by Usuario on 12/11/14.
//  Copyright (c) 2014 p. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageViewAsync : UIImageView<NSURLConnectionDelegate, NSURLSessionDataDelegate> {
    
    NSURLConnection *imageConnection;
    NSMutableData *imageData;
}

-(void)loadFromUrl:(NSString*)url;

@end
