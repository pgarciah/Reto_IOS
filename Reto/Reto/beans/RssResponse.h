//
//  RssResponse.h
//  Reto
//
//  Created by Pablo García on 10/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RssResponse : NSObject

@property (strong,nonatomic) NSMutableArray *items;
@property BOOL error;
@property (strong,nonatomic) NSString *codError;
@property (strong,nonatomic) NSString *msgError;

@end
