//
//  OLPhotobookViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/17/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLKitePrintSDK.h"

@class OLPhotobookPageContentViewController;
@class OLPhotobookViewController;

@protocol OLPhotobookViewControllerDelegate <NSObject>

- (void)photobook:(OLPhotobookViewController *)photobook userDidTapOnImageWithIndex:(NSInteger)index;
- (void)photobook:(OLPhotobookViewController *)photobook userDidLongPressOnImageWithIndex:(NSInteger)index sender:(UILongPressGestureRecognizer *)sender;

@end

@interface OLPhotobookViewController : UIViewController

@property (strong, nonatomic) OLProduct *product;
@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableArray *userSelectedPhotos;
@property (strong, nonatomic) NSNumber *editingPageNumber;
@property (weak, nonatomic) id<OLKiteDelegate> delegate;
@property (weak, nonatomic) id<OLPhotobookViewControllerDelegate> photobookDelegate;
@property (strong, nonatomic) UIPageViewController *pageController;

@property (assign, nonatomic) BOOL editMode;

@end
