//
//  OLPersonalizedProductPhotos.h
//  KitePrintSDK
//
//  Created by Daniel Lau on 4/21/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLProduct;

@interface OLPersonalizedProductPhotos : NSObject

+ (id)sharedManager;

- (BOOL)hasPersonalizedCoverImageForProductGroup:(NSString *)templateClass;

- (void)coverImageForProductGroup:(NSString *)templateClass withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion;

- (void)clearCachedImages;

@end
