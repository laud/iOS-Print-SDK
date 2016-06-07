//
//  UIImage+Extensions.h
//  PhoneMaskTest
//
//  Created by Daniel Lau on 6/6/16.
//  Copyright © 2016 Lau Brothers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extensions)

- (UIImage *)scaleImageToSize:(CGSize)targetSize;
- (UIImage *)scaleAndCropImageToSize:(CGSize)targetSize;
- (UIImage *)maskImageWithMask:(UIImage *)mask;

@end
