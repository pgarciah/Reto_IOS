//
//  UIImageViewAsync.m
//
//  Created by Usuario on 12/11/14.
//  Copyright (c) 2014 p. All rights reserved.
//

#import "UIImageViewAsync.h"

@implementation UIImageViewAsync

#pragma mark - NSURLSessionDataDelegate

/* Fixed ID 2668572 - Insecure Storage: HTTP Response Cache Leak */

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * __nullable ))completionHandler {
    completionHandler(nil);
}

-(void)loadFromUrl:(NSString*)url {

    
    // Datos de la imagen descargada
    imageData = [[NSMutableData alloc] init];
    
    // Creamos la URL
    NSURL* urlImage = [NSURL URLWithString:url];
    
    // Creamos la conexión de datos
    NSURLRequest *request = [NSURLRequest requestWithURL:urlImage
                                             cachePolicy:NSURLCacheStorageNotAllowed
                                         timeoutInterval:30.0];
    
    // Lanzamos la conexión
    imageConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

/**
 *  Recepción de datos asíncrona
 */
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [imageData appendData:data];
}

/**
 *  La conexión finaliza con error; imagen no descargada
 */
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    imageData = nil;
    imageConnection = nil;
}

/**
 *  Conexión finaliza con éxito; imagen descargada
 */
-(void)connectionDidFinishLoading:(NSURLConnection*)connection {
    
    [self setImage:[UIImage imageWithData:imageData]];
    imageData = nil;
    imageConnection = nil;
}

@end
