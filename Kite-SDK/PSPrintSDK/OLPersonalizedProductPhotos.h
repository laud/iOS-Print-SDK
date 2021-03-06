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
+ (void)setAndFadeImage:(UIImage *)image toImageView:(UIImageView *)imageView;

- (BOOL)hasPersonalizedCoverImageForProductGroup:(NSString *)templateClass;

- (void)classImageForProductGroup:(NSString *)templateClass withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion;
- (void)coverImageForProductIdentifier:(NSString *)identifier withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion;
- (void)productImageForProductIdentifier:(NSString *)identifier index:(NSUInteger)i withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion;
- (NSUInteger)remappedIndexForProductIdentifier:(NSString *)identifier originalIndex:(NSUInteger)i;

- (void)clearCachedImages;

@end
