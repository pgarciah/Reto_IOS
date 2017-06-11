//
//  ServiceObject.m
//  Reto
//
//  Created by Pablo García on 10/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

#import "ServiceObject.h"


@implementation ServiceObject

////////////////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION
////////////////////////////////////////////////////////////////////////////////////////////

static NSString *const urlRss = @"https://dl.dropboxusercontent.com/s/upgro4e6ossg0b9/rssReto.xml";
static NSTimeInterval timeoutInterval = 10.0;
static NSString *const codErrorRss = @"GENERIC_ERROR";
static NSString *const msgErrorRss = @"Se ha producido un error";

////////////////////////////////////////////////////////////////////////////////////////////
// METHODS
////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * __nullable ))completionHandler {
    completionHandler(nil);
}

-(RssResponse*) obtainItemsRSS{
    RssResponse *rssresponse = [[RssResponse alloc]init];
    
    NSDictionary *headers = @{ @"cache-control": @"no-cache"};
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlRss]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:timeoutInterval];
    
    
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    [config setTLSMinimumSupportedProtocol:kTLSProtocol12];
    
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    config.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    dispatch_semaphore_t semaphoreRss = dispatch_semaphore_create(0);
    
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        BOOL parserError = YES;
        if (!error && [(NSHTTPURLResponse *)response statusCode] == 200){
            XMLDictionaryParser *parser = [XMLDictionaryParser sharedInstance];
            NSDictionary *responseDictionary = [parser dictionaryWithData:data];
            
            if (responseDictionary){
                NSDictionary *channelDictionary = [responseDictionary objectForKey:@"channel"];
                if(channelDictionary){
                    rssresponse.items = [[NSMutableArray alloc]init];
                    
                    NSDictionary *items = [channelDictionary objectForKey:@"item"];
                    if(items){
                        NSArray *itemsArray = [channelDictionary objectForKey:@"item"];
                        
                        for(int i=0; i<[itemsArray count];i++){
                            NSDictionary *item = [itemsArray objectAtIndex:i];
                            ItemBean *itembean = [[ItemBean alloc]init];
                            itembean.item_id = [item objectForKey:@"guid"];
                            itembean.title = [item objectForKey:@"title"];
                            itembean.desc = [item objectForKey:@"description"];
                            itembean.link = [item objectForKey:@"link"];
                            itembean.date = [item objectForKey:@"pubDate"];
                            itembean.link_image = [item objectForKey:@"src"];
                            [rssresponse.items addObject:itembean];
                        }
                        parserError = NO;
                    }
                }
            }
        }
         rssresponse.error = parserError;
        if(rssresponse.error){
            //ERROR
            rssresponse.codError = codErrorRss;
            rssresponse.msgError = msgErrorRss;
        }
        dispatch_semaphore_signal(semaphoreRss);
    }];
    [dataTask resume];
    
    dispatch_semaphore_wait(semaphoreRss, DISPATCH_TIME_FOREVER);
    
    return rssresponse;
}


@end
