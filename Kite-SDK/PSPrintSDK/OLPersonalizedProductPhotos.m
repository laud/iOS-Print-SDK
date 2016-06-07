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
#import "OLKitePrintSDK.h"
#import "UIImage+Extensions.h"

static NSString *const kMaskURLPrefix = @"https://dimbno61n9ae1.cloudfront.net/";
static NSString *const kCustomPhoneMaskId = @"custom_phone_masked";

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
        
        BOOL okay = NO;
        if ([OLKitePrintSDK productPhotoMaskManifest]) {
            okay = [sharedManager extractAndCheckManifest:[OLKitePrintSDK productPhotoMaskManifest]];
        }
        
        if (!okay) {
            NSDictionary *json;
            NSString * path = [[NSBundle mainBundle] pathForResource:@"ProductPhotoMaskManifest" ofType:@"json"];
            NSString *jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            if (!jsonString) {
                path = [[OLKiteUtils kiteBundle] pathForResource:@"ProductPhotoMaskManifest" ofType:@"json"];
                jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            }
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
            [sharedManager extractAndCheckManifest:json];
        }
    });
    return sharedManager;
}

- (BOOL)extractAndCheckManifest:(NSDictionary *)manifest {
    self.templateClassToPhotoMask = [manifest objectForKey:@"template_class_photo_mask"];
    self.productIdentifierToPhotoMask = [manifest objectForKey:@"product_identifier_photo_mask"];
    self.productImageToPhotoMask = [manifest objectForKey:@"product_image_photo_mask"];
    self.productImageToRemappedIndex = [manifest objectForKey:@"product_image_remapped_index"];
    self.photoMaskManifest = [manifest objectForKey:@"mask_manifest"];
    self.maskIdToURL = [manifest objectForKey:@"image_key_to_path"];
    
    if (!self.templateClassToPhotoMask || !self.productIdentifierToPhotoMask || !self.productImageToPhotoMask ||
        !self.productImageToRemappedIndex || !self.photoMaskManifest || !self.maskIdToURL) {
        return NO;
    } else {
        return YES;
    }
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
    if ([templateClass isEqualToString:@"Snap Cases"]) {
        [self buildPhoneImageWithMask:kCustomPhoneMaskId customImages:customImages completion:^(UIImage *image) {
            completion(image);
        }];
        
    } else {
        NSString *maskId = [self.templateClassToPhotoMask objectForKey:templateClass];
        [self buildCompositeImageWithMask:maskId customImages:customImages completion:^(UIImage *image) {
            completion(image);
        }];
    }
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

- (void)buildPhoneImageWithMask:(NSString *)maskId customImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion {
    // Sanity checks and cacheing
    if (maskId.length == 0) {
        return completion(nil);
    }
    if (!customImages || customImages.count == 0) {
        return completion(nil);
    }
    UIImage *cachedImage = [self.cachedMaskedImages objectForKey:maskId];
    if (cachedImage) {
        return completion(cachedImage);
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSUInteger customImagesStartIndex = arc4random_uniform(42);
        CGFloat scale = [UIScreen mainScreen].scale;
        UIImage *maskImage = [UIImage imageNamedInKiteBundle:@"phone-mask"];
        UIImage *highlightImage = [UIImage imageNamedInKiteBundle:@"phone-effects"];
        UIImage *backgroundImage = [UIImage imageNamedInKiteBundle:@"phone-background"];
        
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
                [imageManager requestImageForAsset:phAsset targetSize:CGSizeMake(maskImage.size.width * scale, maskImage.size.height * scale) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                    UIImage *finalImage = [self constructPhoneImage:maskImage
                                                          highlight:highlightImage
                                                         background:backgroundImage
                                                         foreground:result
                                                          phoneSize:CGSizeMake(235.2, 475)
                                                        phoneCenter:CGSizeMake(351, 290)
                                                      phoneRotation:11.94];
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        if (finalImage) {
                            [self.cachedMaskedImages setObject:finalImage forKey:maskId];
                        }
                        completion(finalImage);
                    });
                }];
            } else {
                NSLog(@"\tSkip Mask: PHAsset not found");
                return completion(nil);
            }
        } else {
            NSLog(@"\tSkip Mask: Not OLAsset");
            return completion(nil);
        }
    });
}

- (UIImage *)constructPhoneImage:(UIImage *)phoneMask
                       highlight:(UIImage *)highlight
                      background:(UIImage *)background
                      foreground:(UIImage *)foreground
                       phoneSize:(CGSize)phoneSize
                     phoneCenter:(CGSize)phoneCenter
                   phoneRotation:(CGFloat)rotation {
    
    // Construct phone mask and then resize to original mask image size
    UIImage *maskedImage = [foreground maskImageWithMask:phoneMask];
    maskedImage = [maskedImage scaleImageToSize:phoneMask.size];
    
    // Add blended image on top of masked image
    UIGraphicsBeginImageContextWithOptions(maskedImage.size, NO, 0);
    [maskedImage drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
    [highlight drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
    UIImage *blendedImage = UIGraphicsGetImageFromCurrentImageContext();
    blendedImage = [blendedImage scaleImageToSize:phoneSize];
    UIGraphicsEndImageContext();
    
    // Add compound phone image to background image
    UIGraphicsBeginImageContextWithOptions(background.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [background drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
    CGContextTranslateCTM(context, phoneCenter.width - blendedImage.size.width/2.f, phoneCenter.height - blendedImage.size.height/2.f);
    CGContextTranslateCTM(context, blendedImage.size.width/2.f, blendedImage.size.height/2.f);
    CGContextRotateCTM(context, DegreesToRadians(rotation));
    CGContextTranslateCTM(context, -blendedImage.size.width/2.f, -blendedImage.size.height/2.f);
    [blendedImage drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}

- (void)clearCachedImages {
    [self.cachedMaskedImages removeAllObjects];
}

@end
