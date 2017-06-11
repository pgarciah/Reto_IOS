//
//  ItemBean.h
//  Reto
//
//  Created by Pablo García on 9/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ItemBean : NSObject<NSCoding>

@property (strong,nonatomic) NSString *item_id;
@property (strong,nonatomic) NSString *title;
@property (strong,nonatomic) NSString *desc;
@property (strong,nonatomic) NSString *link;
@property (strong,nonatomic) NSString *date;
@property (strong,nonatomic) NSString *link_image;

@end
