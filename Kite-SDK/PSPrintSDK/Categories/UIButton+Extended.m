//
//  UIButton+Extended.m
//  BabyArt
//
//  Created by Daniel Lau on 5/10/16.
//  Copyright © 2016 Lau Brothers LLC. All rights reserved.
//

#import "UIButton+Extended.h"

@implementation UIButton (Extended)

- (CGSize)intrinsicContentSize {
    CGSize s = [super intrinsicContentSize];
    
    return CGSizeMake(s.width + self.titleEdgeInsets.left + self.titleEdgeInsets.right,
                      s.height + self.titleEdgeInsets.top + self.titleEdgeInsets.bottom);
}

@end
