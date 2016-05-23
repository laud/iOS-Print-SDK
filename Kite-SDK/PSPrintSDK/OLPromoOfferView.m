//
//  PromoOfferView.m
//  KitePrintSDK
//
//  Created by Daniel Lau on 5/23/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import "OLPromoOfferView.h"
#import "OLKitePrintSDK.h"
#import "UIButton+Extended.h"

const NSInteger kOLKiteSDKPromoOfferUnlockedLabelTag = 77;
const NSInteger kOLKiteSDKPromoOfferLockedLabelTag = 78;
const NSInteger kOLKiteSDKPromoOfferLockedButtonTag = 79;

@implementation OLPromoOfferView

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

+ (void)constructPromoOfferViewOnSuperview:(nullable UIView *)superview withTarget:(nullable id)target {
    UILabel *unlockedLabel;
    UILabel *lockedLabel;
    UIButton *lockedButton;
    
    unlockedLabel = [[UILabel alloc] init];
    unlockedLabel.tag = 77;
    unlockedLabel.textAlignment = NSTextAlignmentCenter;
    unlockedLabel.font = [UIFont systemFontOfSize:14];
    unlockedLabel.adjustsFontSizeToFitWidth = YES;
    unlockedLabel.minimumScaleFactor = 0.5;
    unlockedLabel.text = [OLKitePrintSDK topBannerUnlockedCopy];
    unlockedLabel.textColor = [UIColor colorWithRed:106/255.f green:6/255.f blue:225/255.f alpha:1];
    [superview addSubview:unlockedLabel];
    
    unlockedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(unlockedLabel);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-(>=10)-[unlockedLabel]-(>=10)-|",
                         @"V:|-0-[unlockedLabel]-0-|"];
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    [con addObject:[NSLayoutConstraint constraintWithItem:unlockedLabel
                                                attribute:NSLayoutAttributeCenterX
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:unlockedLabel.superview
                                                attribute:NSLayoutAttributeCenterX
                                               multiplier:1.f constant:0.f]];
    [unlockedLabel.superview addConstraints:con];
    
    // Locked UI components
    lockedLabel = [[UILabel alloc] init];
    lockedLabel.tag = 78;
    lockedLabel.textAlignment = NSTextAlignmentCenter;
    lockedLabel.font = [UIFont systemFontOfSize:14];
    lockedLabel.adjustsFontSizeToFitWidth = YES;
    lockedLabel.minimumScaleFactor = 0.5;
    lockedLabel.text = [OLKitePrintSDK topBannerLockedCopy];
    lockedLabel.textColor = [UIColor colorWithRed:106/255.f green:6/255.f blue:225/255.f alpha:1];
    lockedLabel.userInteractionEnabled = YES;
    if ([target respondsToSelector:@selector(unlockOfferTap:)]) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target
                                                                              action:@selector(unlockOfferTap:)];
        [lockedLabel addGestureRecognizer:tap];
    }
    [superview addSubview:lockedLabel];
    
    lockedButton = [UIButton buttonWithType:UIButtonTypeSystem];
    lockedButton.tag = 79;
    lockedButton.titleLabel.font = [UIFont systemFontOfSize:14];
    lockedButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    lockedButton.titleLabel.minimumScaleFactor = 0.5;
    lockedButton.layer.borderWidth = 1.f;
    lockedButton.layer.borderColor = [UIColor colorWithRed:106/255.f green:6/255.f blue:225/255.f alpha:1].CGColor;
    lockedButton.layer.cornerRadius = 5.f;
    lockedButton.layer.masksToBounds = YES;
    [lockedButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 8.0, 0.0, 8.0)];
    [lockedButton setTitle:[OLKitePrintSDK topBannerLockedButtonCopy] forState:UIControlStateNormal];
    [lockedButton sizeToFit];
    [lockedButton setTitleColor:[UIColor colorWithRed:106/255.f green:6/255.f blue:225/255.f alpha:1] forState:UIControlStateNormal];
    if ([target respondsToSelector:@selector(unlockOfferPressed:)]) {
        [lockedButton addTarget:target action:@selector(unlockOfferPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    [superview addSubview:lockedButton];
    
    lockedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    lockedButton.translatesAutoresizingMaskIntoConstraints = NO;
    views = NSDictionaryOfVariableBindings(lockedLabel, lockedButton);
    con = [[NSMutableArray alloc] init];
    
    visuals = @[@"H:|-10-[lockedLabel]-8-[lockedButton(<=150)]-10-|",
                @"V:|-0-[lockedLabel]-0-|",
                @"V:|-8-[lockedButton]-8-|"];
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    [lockedLabel.superview addConstraints:con];
}

#pragma clang diagnostic pop

+ (void)resetPromoOfferSubviewVisilibity:(nullable UIView *)superview {
    UILabel *unlockedLabel = (UILabel *)[superview viewWithTag:kOLKiteSDKPromoOfferUnlockedLabelTag];
    UILabel *lockedLabel = (UILabel *)[superview viewWithTag:kOLKiteSDKPromoOfferLockedLabelTag];
    UIButton *lockedButton = (UIButton *)[superview viewWithTag:kOLKiteSDKPromoOfferLockedButtonTag];
    if ([OLKitePrintSDK promoOfferUnlocked]) {
        unlockedLabel.hidden = NO;
        lockedLabel.hidden = YES;
        lockedButton.hidden = YES;
    } else {
        unlockedLabel.hidden = YES;
        lockedLabel.hidden = NO;
        lockedButton.hidden = NO;
    }
}


@end
