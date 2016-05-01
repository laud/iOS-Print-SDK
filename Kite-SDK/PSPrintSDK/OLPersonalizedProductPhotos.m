//
//  OLPersonalizedProductPhotos.m
//  KitePrintSDK
//
//  Created by Daniel Lau on 4/21/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

@import Photos;

#ifdef COCOAPODS
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDWebImagePrefetcher.h>
#else
#import "SDWebImageManager.h"
#import "SDWebImagePrefetcher.h"
#endif

#import "OLPersonalizedProductPhotos.h"
#import "OLPrintPhoto.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLKiteUtils.h"

static NSString *const kMaskURLPrefix = @"https://dimbno61n9ae1.cloudfront.net/";

@interface OLPersonalizedProductPhotos ()

@property NSDictionary *templateClassToPhotoMask;
@property NSDictionary *maskIdToURL;
@property NSDictionary *productIdentifierToPhotoMask;
@property NSDictionary *productImageToPhotoMask;
@property NSDictionary *productImageToRemappedIndex;

@property NSDictionary *photoMaskManifest;
@property NSMutableDictionary *cachedMaskedImages;

@end

@implementation OLPersonalizedProductPhotos

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

+ (id)sharedManager {
    static OLPersonalizedProductPhotos *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        sharedManager.cachedMaskedImages = [NSMutableDictionary dictionary];

        NSString * path = [[NSBundle mainBundle] pathForResource:@"ProductPhotoMaskManifest" ofType:@"json"];
        NSString *jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (!jsonString) {
            path = [[OLKiteUtils kiteBundle] pathForResource:@"ProductPhotoMaskManifest" ofType:@"json"];
            jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        }
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        
        sharedManager.templateClassToPhotoMask = [json objectForKey:@"template_class_photo_mask"];
        sharedManager.productIdentifierToPhotoMask = [json objectForKey:@"product_identifier_photo_mask"];
        sharedManager.productImageToPhotoMask = [json objectForKey:@"product_image_photo_mask"];
        sharedManager.productImageToRemappedIndex = [json objectForKey:@"product_image_remapped_index"];
        sharedManager.photoMaskManifest = [json objectForKey:@"mask_manifest"];
        sharedManager.maskIdToURL = [json objectForKey:@"image_key_to_path"];
    });
    return sharedManager;
}

+ (void)setAndFadeImage:(UIImage *)image toImageView:(UIImageView *)imageView {
    imageView.image = image;
    imageView.alpha = 0;
    [UIView beginAnimations:@"fadeIn" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.3];
    imageView.alpha = 1;
    [UIView commitAnimations];
}

- (BOOL)hasPersonalizedCoverImageForProductGroup:(NSString *)templateClass {
    NSString *photoMaskId = [self.templateClassToPhotoMask objectForKey:templateClass];
    if (photoMaskId.length == 0) {
        return NO;
    }
    NSArray *photoMaskManifest = [self.photoMaskManifest objectForKey:photoMaskId];
    if (photoMaskManifest.count == 0) {
        return NO;
    }
    return YES;
}

- (void)classImageForProductGroup:(NSString *)templateClass withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion {
    
    NSString *maskId = [self.templateClassToPhotoMask objectForKey:templateClass];
    [self buildCompositeImageWithMask:maskId customImages:customImages completion:^(UIImage *image) {
        completion(image);
    }];
}

- (void)coverImageForProductIdentifier:(NSString *)identifier withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion {
    
    NSString *maskId = [self.productIdentifierToPhotoMask objectForKey:identifier];
    [self buildCompositeImageWithMask:maskId customImages:customImages completion:^(UIImage *image) {
        completion(image);
    }];
}

- (void)productImageForProductIdentifier:(NSString *)identifier index:(NSUInteger)i withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion {
    
    NSString *key = i > 0 ? [NSString stringWithFormat:@"%@_%lu", identifier, (unsigned long)(i+1)] : identifier;
    NSString *maskId = [self.productImageToPhotoMask objectForKey:key];
    [self buildCompositeImageWithMask:maskId customImages:customImages completion:^(UIImage *image) {
        completion(image);
    }];
}

- (NSUInteger)remappedIndexForProductIdentifier:(NSString *)identifier originalIndex:(NSUInteger)i {
    NSString *key = [NSString stringWithFormat:@"%@_%ld", identifier, (unsigned long)i];
    NSNumber *remappedIndex = [self.productImageToRemappedIndex objectForKey:key];
    if (remappedIndex) {
        return [remappedIndex unsignedIntegerValue];
    }
    return i;
}

- (NSString *)urlForMask:(NSString *)maskId {
    NSString *path = [self.maskIdToURL objectForKey:maskId];
    return path.length > 0 ? [NSString stringWithFormat:@"%@%@", kMaskURLPrefix, path] : nil;
}

- (void)buildCompositeImageWithMask:(NSString *)maskId customImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion {
    // Sanity checks and cacheing
    if (maskId.length == 0) {
        return completion(nil);
    }
    if ([self urlForMask:maskId].length == 0) {
        return completion(nil);
    }
    if (!customImages || customImages.count == 0) {
        return completion(nil);
    }
    NSArray *maskManifest = [self.photoMaskManifest objectForKey:maskId];
    if (maskManifest.count == 0) {
        return completion(nil);
    }
    UIImage *cachedImage = [self.cachedMaskedImages objectForKey:maskId];
    if (cachedImage) {
        return completion(cachedImage);
    }
    
    // The real work
    NSURL *url = [NSURL URLWithString:[self urlForMask:maskId]];
    [[SDWebImageManager sharedManager] downloadImageWithURL:url options:0 progress:NULL completed:^(UIImage *mask, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
        if (!mask || error) {
            return completion(nil);
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            UIGraphicsBeginImageContextWithOptions(mask.size, FALSE, 0.0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            NSUInteger customImagesStartIndex = arc4random_uniform(42);
            CGFloat scale = [UIScreen mainScreen].scale;
            
            // Add customer photos into context
            for (NSDictionary *maskInfo in maskManifest) {
                CGFloat x = [maskInfo[@"x"] floatValue] * mask.size.width;
                CGFloat y = [maskInfo[@"y"] floatValue] * mask.size.height;
                CGFloat width = [maskInfo[@"width"] floatValue] * mask.size.width;
                CGFloat height = [maskInfo[@"height"] floatValue] * mask.size.height;
                CGFloat rotate = [maskInfo[@"angle"] floatValue];
                
                // We do this process manually because we need a much smaller targetSize than that fetched from KiteSDK
                OLPrintPhoto *printPhoto = [customImages objectAtIndex:customImagesStartIndex % customImages.count];
                if (printPhoto.type == kPrintPhotoAssetTypeOLAsset) {
                    PHAsset *phAsset = [((OLAsset *)printPhoto.asset) loadPHAsset];
                    if (phAsset) {
                        PHImageManager *imageManager = [PHImageManager defaultManager];
                        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                        options.synchronous = YES;
                        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                        options.resizeMode = PHImageRequestOptionsResizeModeFast;
                        options.networkAccessAllowed = YES;
                        [imageManager requestImageForAsset:phAsset targetSize:CGSizeMake(width * scale, height * scale) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                            UIImageView *photoImageView = [[UIImageView alloc] initWithImage:result];
                            photoImageView.contentMode = UIViewContentModeScaleAspectFill;
                            photoImageView.frame = CGRectMake(x, y, width, height);
                            photoImageView.layer.masksToBounds = YES;
                            
                            // Add photo to context
                            CGContextSaveGState(context);
                            CGContextTranslateCTM(context, x, y);
                            // Only rotate if angle is above epsilon
                            if (fabs(rotate) > 0.01) {
                                CGContextRotateCTM(context, DegreesToRadians(rotate));
                            }
                            [photoImageView.layer renderInContext:context];
                            CGContextRestoreGState(context);
                        }];
                    } else {
                        NSLog(@"\tSkip Mask: PHAsset not found");
                        return completion(nil);
                    }
                } else {
                    NSLog(@"\tSkip Mask: Not OLAsset");
                    return completion(nil);
                }
                customImagesStartIndex++;
            }
            
            // Draw mask above all photos
            [mask drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
            UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (finalImage) {
                    [self.cachedMaskedImages setObject:finalImage forKey:maskId];
                }
                completion(finalImage);
            });
        });
    }];
}

- (void)clearCachedImages {
    [self.cachedMaskedImages removeAllObjects];
}

@end
