//
//  ItemBean.m
//  Reto
//
//  Created by Pablo García on 9/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

#import "ItemBean.h"

@implementation ItemBean

- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:_item_id forKey:@"item_id"];
    [coder encodeObject:_title forKey:@"title"];
    [coder encodeObject:_desc forKey:@"desc"];
    [coder encodeObject:_link forKey:@"link"];
    [coder encodeObject:_date forKey:@"date"];
    [coder encodeObject:_link_image forKey:@"link_image"];
}

- (id)initWithCoder:(NSCoder *)coder{
    self = [super init];
    if (self != nil){
        _item_id = [coder decodeObjectForKey:@"item_id"];
        _title = [coder decodeObjectForKey:@"title"];
        _desc = [coder decodeObjectForKey:@"desc"];
        _link = [coder decodeObjectForKey:@"link"];
        _date = [coder decodeObjectForKey:@"date"];
        _link_image = [coder decodeObjectForKey:@"link_image"];
    }
    return self;
}

- (NSComparisonResult)compararOrdenData:(ItemBean*)otherBean {
    if(_date!=nil){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat: @"dd/MM/yyyy"];  //@"yyyy-MM-dd"
        NSDate *date1 = [dateFormatter dateFromString:_date];
        NSDate *date2 = [dateFormatter dateFromString:otherBean.date];
        
        return [date1 compare:date2];
    }
    return [self.title compare:otherBean.title];
}

- (NSComparisonResult)compararOrdenDataInverso:(ItemBean*)otherBean {
    if(_date!=nil){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat: @"dd/MM/yyyy"];  //@"yyyy-MM-dd"
        NSDate *date1 = [dateFormatter dateFromString:_date];
        NSDate *date2 = [dateFormatter dateFromString:otherBean.date];
        
        return [date2 compare:date1];
    }
    return [self.title compare:otherBean.title];
}

@end
