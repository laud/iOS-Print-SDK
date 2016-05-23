//
//  PromoOfferView.h
//  KitePrintSDK
//
//  Created by Daniel Lau on 5/23/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const NSInteger kOLKiteSDKPromoOfferUnlockedLabelTag;
extern const NSInteger kOLKiteSDKPromoOfferLockedLabelTag;
extern const NSInteger kOLKiteSDKPromoOfferLockedButtonTag;

@interface PromoOfferView : NSObject

+ (void)constructPromoOfferViewOnSuperview:(nullable UIView *)superview withTarget:(nullable id)target;

+ (void)resetPromoOfferSubviewVisilibity:(nullable UIView *)superview;

@end
