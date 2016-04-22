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

@interface OLPersonalizedProductPhotos ()

@property NSDictionary *templateClassToPhotoMask;
@property NSDictionary *photoMaskManifest;
@property NSMutableDictionary *cachedMaskedImages;

@end

@implementation OLPersonalizedProductPhotos

+ (id)sharedManager {
    static OLPersonalizedProductPhotos *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        sharedManager.templateClassToPhotoMask = @{
                                                   @"Posters": @"poster_mask"
                                                   };
        
        NSString * path = [[NSBundle mainBundle] pathForResource:@"PhotoMaskManifest" ofType:@"json"];
        NSString* jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        sharedManager.photoMaskManifest = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        sharedManager.cachedMaskedImages = [NSMutableDictionary dictionary];
        
    });
    return sharedManager;
}

- (BOOL)hasPersonalizedCoverImageForProductGroup:(NSString *)templateClass {
    return ([self.templateClassToPhotoMask objectForKey:templateClass] != nil);
}

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

- (void)coverImageForProductGroup:(NSString *)templateClass withCustomImages:(NSArray *)customImages completion:(void (^)(UIImage *image))completion {
    templateClass = @"Posters";
    NSString *photoMaskId = [self.templateClassToPhotoMask objectForKey:templateClass];
    if (photoMaskId.length == 0) {
        NSLog(@"Mask ID Missing");
        return completion(nil);
    }
    if (!customImages || customImages.count == 0) {
        NSLog(@"Not enough custom images");
        return completion(nil);
    }
    NSArray *photoMaskManifest = [self.photoMaskManifest objectForKey:photoMaskId];
    if (!photoMaskManifest) {
        NSLog(@"Mask manifest missing");
        return completion(nil);
    }
    UIImage *cachedImage = [self.cachedMaskedImages objectForKey:photoMaskId];
    if (cachedImage) {
        NSLog(@"Cached image found, return!");
        return completion(cachedImage);
    }
    
    NSDictionary *maskInfo = [photoMaskManifest firstObject];
    CGFloat x = [maskInfo[@"x"] floatValue];
    CGFloat y = [maskInfo[@"y"] floatValue];
    CGFloat width = [maskInfo[@"width"] floatValue];
    CGFloat height = [maskInfo[@"height"] floatValue];
    CGFloat rotate = [maskInfo[@"angle"] floatValue];

    UIImage *mask = [UIImage imageNamed:photoMaskId];

    NSUInteger randomIndex = arc4random_uniform(42) % customImages.count;
    OLPrintPhoto *printPhoto = [customImages objectAtIndex:randomIndex];
    if (printPhoto.type == kPrintPhotoAssetTypeOLAsset) {
        PHAsset *phAsset = [((OLAsset *)printPhoto.asset) loadPHAsset];
        if (phAsset) {
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = NO;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = YES;
            [imageManager requestImageForAsset:phAsset targetSize:mask.size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                __block UIImage *finalImage;
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    @autoreleasepool {
                        UIImageView *photoImageView = [[UIImageView alloc] initWithImage:result];
                        photoImageView.contentMode = UIViewContentModeScaleAspectFill;
                        photoImageView.frame = CGRectMake(x, y, width, height);
                        photoImageView.layer.masksToBounds = YES;
            
                        UIGraphicsBeginImageContextWithOptions(mask.size, FALSE, 0.0);
                        CGContextRef context = UIGraphicsGetCurrentContext();
                        CGContextSaveGState(context);
                        CGContextTranslateCTM(context, x, y);
                        CGContextRotateCTM(context, DegreesToRadians(rotate));
                        [photoImageView.layer renderInContext:context];
                        CGContextRestoreGState(context);
                        [mask drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
                        finalImage = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                    }
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        completion(finalImage);
//                        [self.cachedMaskedImages setObject:finalImage forKey:photoMaskId];
                        finalImage = nil;
                        return;
                    });
                });
            }];
        } else {
            NSLog(@"PHAsset not found");
            return completion(nil);
        }
    } else {
        NSLog(@"Not OLAsset");
        return completion(nil);
    }
}

- (void)clearCachedImages {
    [self.cachedMaskedImages removeAllObjects];
}


@end
