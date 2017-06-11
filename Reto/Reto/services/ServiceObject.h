//
//  ServiceObject.h
//  Reto
//
//  Created by Pablo García on 10/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLDictionary.h"
#import "RssResponse.h"
#import "ItemBean.h"


@protocol ServicesProtocol

@required
-(RssResponse*) obtainItemsRSS;

@end

@interface ServiceObject : NSObject<ServicesProtocol,NSURLSessionDataDelegate>

@end
