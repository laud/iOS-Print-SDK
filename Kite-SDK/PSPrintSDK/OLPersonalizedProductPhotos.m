//
//  OLPersonalizedProductPhotos.m
//  KitePrintSDK
//
//  Created by Daniel Lau on 4/21/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

@import Photos;

#import "OLPersonalizedProductPhotos.h"
#import "OLPrintPhoto.h"
#import "UIImage+ImageNamedInKiteBundle.h"

@interface OLPersonalizedProductPhotos ()

@property NSDictionary *templateClassToPhotoMask;
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
        sharedManager.templateClassToPhotoMask = @{
                                                   @"Posters"           : @"poster_mask",
                                                   @"Magnets"           : @"magnets_mask",
                                                   @"Photo Magnets"     : @"magnets_mask",
                                                   };
        
        NSString * path = [[NSBundle mainBundle] pathForResource:@"PhotoMaskManifest" ofType:@"json"];
        NSString* jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        sharedManager.photoMaskManifest = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        sharedManager.cachedMaskedImages = [NSMutableDictionary dictionary];
        
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

- (void)coverImageForProductGroup:(NSString *)templateClass withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion {
    NSString *maskId = [self.templateClassToPhotoMask objectForKey:templateClass];
    if (maskId.length == 0) {
        NSLog(@"\tSkip Mask: Mask ID Missing");
        return completion(nil);
    }
    if (!customImages || customImages.count == 0) {
        NSLog(@"\tSkip Mask: Not enough custom images");
        return completion(nil);
    }
    NSArray *maskManifest = [self.photoMaskManifest objectForKey:maskId];
    if (maskManifest.count == 0) {
        NSLog(@"\tSkip Mask: Mask manifest missing for %@", maskId);
        return completion(nil);
    }
    UIImage *cachedImage = [self.cachedMaskedImages objectForKey:maskId];
    if (cachedImage) {
        NSLog(@"Returning cached image");
        return completion(cachedImage);
    }
    
    [self buildCompositeImageWithMask:maskId maskManifest:maskManifest customImages:customImages completion:^(UIImage *image) {
        completion(image);
    }];
}

- (void)buildCompositeImageWithMask:(NSString *)maskId maskManifest:(NSArray *)maskManifest customImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        UIImage *mask = [UIImage imageNamedInKiteBundle:maskId];
        UIGraphicsBeginImageContextWithOptions(mask.size, FALSE, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        NSUInteger customImagesStartIndex = arc4random_uniform(42);
        CGFloat scale = [UIScreen mainScreen].scale;
        
        // Add customer photos into context
        for (NSDictionary *maskInfo in maskManifest) {
            CGFloat x = [maskInfo[@"x"] floatValue];
            CGFloat y = [maskInfo[@"y"] floatValue];
            CGFloat width = [maskInfo[@"width"] floatValue];
            CGFloat height = [maskInfo[@"height"] floatValue];
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
            [self.cachedMaskedImages setObject:finalImage forKey:maskId];
            completion(finalImage);
        });
    });
}

- (void)clearCachedImages {
    [self.cachedMaskedImages removeAllObjects];
}

@end
