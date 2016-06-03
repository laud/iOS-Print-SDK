//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

/**********************************************************************
 * Insert your API keys here. These are found under your profile
 * by logging in to the developer portal at https://www.kite.ly
 **********************************************************************/
static NSString *const kAPIKeySandbox = @"825ac536d022c4660cfabe26b4166ca21a9edc8b"; // replace with your Sandbox API key found under the Profile section in the developer portal
static NSString *const kAPIKeyLive = @"REPLACE_WITH_YOUR_API_KEY"; // replace with your Live API key found under the Profile section in the developer portal

static NSString *const kApplePayMerchantIDKey = @"merchant.ly.kite.sdk"; // Replace with your merchant ID
static NSString *const kApplePayBusinessName = @"Kite.ly"; //Replace with your business name

#import "ViewController.h"
#import "OLKitePrintSDK.h"
#import "OLAssetsPickerController.h"
#import "OLImageCachingManager.h"
#import "CatsAssetCollectionDataSource.h"
#import "DogsAssetCollectionDataSource.h"

#ifdef OL_KITE_AT_LEAST_IOS8
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#endif

#import <AssetsLibrary/AssetsLibrary.h>
@import Photos;

@interface ViewController () <OLAssetsPickerControllerDelegate,
#ifdef OL_KITE_AT_LEAST_IOS8
CTAssetsPickerControllerDelegate,
#endif
UINavigationControllerDelegate, OLKiteDelegate>
@property (weak, nonatomic) IBOutlet UIButton *localPhotosButton;
@property (weak, nonatomic) IBOutlet UIButton *remotePhotosButton;
@property (nonatomic, weak) IBOutlet UISegmentedControl *environmentPicker;
@property (nonatomic, strong) OLPrintOrder* printOrder;
@end

@interface OLKitePrintSDK (Private)
+ (void)setUseStaging:(BOOL)staging;
@end

@implementation ViewController

-(void)viewDidAppear:(BOOL)animated{
    self.printOrder = [[OLPrintOrder alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifdef OL_KITE_OFFER_INSTAGRAM
    [OLKitePrintSDK setInstagramEnabledWithClientID:@"a6a09c92a14d488baa471e5209906d3d" secret:@"bfb814274cd041a5b7e06f32608e0e87" redirectURI:@"kite://instagram-callback"];
#endif
    
#ifdef OL_KITE_OFFER_APPLE_PAY
    [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
    [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
#endif
    
    [OLKitePrintSDK setTopBannerUnlockedCopy:@"WELCOME20 promo code to get 20% off your first order!"];
    [OLKitePrintSDK setTopBannerLockedCopy:@"Tap to unlock 20% OFF! :D"];
    [OLKitePrintSDK setTopBannerLockedButtonCopy:@"Unlock"];
    [OLKitePrintSDK setPromoCodeAvailable:YES];

    // Just short circuit testing
//    [self onButtonPrintLocalPhotos:nil];
    PHFetchOptions *fetch = [[PHFetchOptions alloc] init];
    fetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    fetch.fetchLimit = 6;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:fetch];
    NSMutableArray *assetObjects = [NSMutableArray array];
    [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([asset isKindOfClass:[PHAsset class]]){
            [assetObjects addObject:[OLAsset assetWithPHAsset:asset]];
        }
    }];
    [self printWithAssets:assetObjects];

}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)onButtonPrintLocalPhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    __block UIViewController *picker;
    __block Class assetClass;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8 || !definesAtLeastiOS8){
        picker = [[OLAssetsPickerController alloc] init];
        [(OLAssetsPickerController *)picker setAssetsFilter:[ALAssetsFilter allPhotos]];
        assetClass = [ALAsset class];
        ((OLAssetsPickerController *)picker).delegate = self;
    }
#ifdef OL_KITE_AT_LEAST_IOS8
    else{
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined){
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                if (status == PHAuthorizationStatusAuthorized){
                    picker = [[CTAssetsPickerController alloc] init];
                    ((CTAssetsPickerController *)picker).showsEmptyAlbums = NO;
                    PHFetchOptions *options = [[PHFetchOptions alloc] init];
                    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
                    ((CTAssetsPickerController *)picker).assetsFetchOptions = options;
                    assetClass = [PHAsset class];
                    ((CTAssetsPickerController *)picker).delegate = self;
                    [self presentViewController:picker animated:YES completion:nil];
                }
            }];
        }
        else{
            picker = [[CTAssetsPickerController alloc] init];
            ((CTAssetsPickerController *)picker).showsEmptyAlbums = NO;
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
            ((CTAssetsPickerController *)picker).assetsFetchOptions = options;
            assetClass = [PHAsset class];
            ((CTAssetsPickerController *)picker).delegate = self;
        }
    }
#endif
    if (picker){
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (NSString *)apiKey {
    if ([self environment] == kOLKitePrintSDKEnvironmentSandbox) {
        return kAPIKeySandbox;
    } else {
        return kAPIKeyLive;
    }
}

- (NSString *)liveKey {
    return kAPIKeyLive;
}

- (NSString *)sandboxKey {
    return kAPIKeySandbox;
}

- (BOOL)isAPIKeySet {
#ifdef OL_KITE_CI_DEPLOY
    return YES;
#endif

    if (![[[NSProcessInfo processInfo]environment][@"OL_KITE_UI_TEST"] isEqualToString:@"1"]){
        if ([[self apiKey] isEqualToString:@"REPLACE_WITH_YOUR_API_KEY"] && ![OLKitePrintSDK apiKey]) {
            [[[UIAlertView alloc] initWithTitle:@"API Key Required" message:@"Set your API keys at the top of ViewController.m before you can print. This can be found under your profile at http://kite.ly" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return NO;
        }
    }
    else{
        [OLKitePrintSDK setAPIKey:[[NSProcessInfo processInfo]environment][@"TEST_API_KEY"] withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
    }
    
    [OLKitePrintSDK setAPIKey:kAPIKeySandbox withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
    [OLProductTemplate sync];
    return YES;
}

- (OLKitePrintSDKEnvironment)environment {
    if (self.environmentPicker.selectedSegmentIndex == 0) {
        return kOLKitePrintSDKEnvironmentSandbox;
    } else {
        return kOLKitePrintSDKEnvironmentLive;
    }
}

- (void)printWithAssets:(NSArray *)assets {
#ifdef OL_KITE_CI_DEPLOY
    [self setupCIDeploymentWithAssets:assets];
    return;
#else
    if (![[[NSProcessInfo processInfo]environment][@"OL_KITE_UI_TEST"] isEqualToString:@"1"]){
        if (![self isAPIKeySet]) return;
        [OLKitePrintSDK setAPIKey:[self apiKey] withEnvironment:[self environment]];
    }
#endif
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    vc.userEmail = @"";
    vc.userPhone = @"";
    vc.delegate = self;
    [vc addCustomPhotoProviderWithCollections:@[[[CatsAssetCollectionDataSource alloc] init]] name:@"Cats" icon:[UIImage imageNamed:@"cat"]];
    [vc addCustomPhotoProviderWithCollections:@[[[DogsAssetCollectionDataSource alloc] init]] name:@"Dogs" icon:[UIImage imageNamed:@"dog"]];
    [self presentViewController:vc animated:YES completion:NULL];
    
    //Register for push notifications
    NSUInteger types = (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:
         [UIUserNotificationSettings settingsForTypes:types categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    //    else {
    //        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
    //    }
    
}

- (IBAction)onButtonPrintRemotePhotos:(id)sender {
    if (![self isAPIKeySet]) return;
    [[[UIAlertView alloc] initWithTitle:@"Remote URLS" message:@"Feel free to Change hardcoded remote image URLs in ViewController.m onButtonPrintRemotePhotos:" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]];
    
    [self printWithAssets:assets];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:^(void) {
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [self printWithAssets:@[[OLAsset assetWithImageAsJPEG:chosenImage]]];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CTAssetsPickerControllerDelegate Methods
- (void)assetsPickerController:(id)picker didFinishPickingAssets:(NSArray *)assets {
    [picker dismissViewControllerAnimated:YES completion:^(void){
        NSMutableArray *assetObjects = [[NSMutableArray alloc] initWithCapacity:assets.count];
        for (id asset in assets){
            if ([asset isKindOfClass:[PHAsset class]]){
                [assetObjects addObject:[OLAsset assetWithPHAsset:asset]];
            }
            else if([asset isKindOfClass:[ALAsset class]]){
                [assetObjects addObject:[OLAsset assetWithALAsset:asset]];
            }
            else{
                NSLog(@"Oops, don’t recognize class %@, starting with no assets", [asset class]);
            }
        }
        [self printWithAssets:assetObjects];
    }];
    
}

#ifdef OL_KITE_AT_LEAST_IOS8
- (void)assetsPickerController:(CTAssetsPickerController *)picker didDeSelectAsset:(PHAsset *)asset{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager stopCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didSelectAsset:(PHAsset *)asset{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[OLImageCachingManager sharedInstance].photosCachingManager startCachingImagesForAssets:@[asset] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options];
}

#endif

- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker shouldShowAssetsGroup:(ALAssetsGroup *)group{
    if (group.numberOfAssets == 0){
        return NO;
    }
    return YES;
}

- (BOOL)assetsPickerController:(OLAssetsPickerController *)picker shouldShowAsset:(id)asset{
    NSString *fileName = [[[asset defaultRepresentation] filename] lowercaseString];
    if (!([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"] || [fileName hasSuffix:@"png"] || [fileName hasSuffix:@"tiff"])) {
        return NO;
    }
    return YES;
}

#pragma mark - OLKiteDelete

- (BOOL)kiteController:(OLKiteViewController *)controller isDefaultAssetsGroup:(ALAssetsGroup *)group {
    //    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"Instagram"]) {
    //        return YES;
    //    }
    return NO;
}

- (BOOL)kiteControllerShouldAllowUserToAddMorePhotos:(OLKiteViewController *)controller {
    return YES;
}

//- (BOOL)shouldShowOptOutOfEmailsCheckbox{
//    return YES;
//}

//- (BOOL)shouldShowPhoneEntryOnCheckoutScreen{
//    return YES;
//}

- (IBAction)onButtonKiteClicked:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.kite.ly"]];
}

- (BOOL)shouldShowContinueShoppingButton{
    return YES;
}

- (void)logKiteAnalyticsEventWithInfo:(NSDictionary *)info{
    NSLog(@"%@", info);
}

- (void)kiteControllerDidUnlockStoreOffer:(NSDictionary *_Nonnull)info {
    NSLog(@"unlock delegate received");
}

#pragma mark Internal

- (void)setupCIDeploymentWithAssets:(NSArray *)assets{
    BOOL shouldOfferAPIChange = [[[UIDevice currentDevice] systemVersion] floatValue] >= 8;
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    if (!([pasteboard containsPasteboardTypes: [NSArray arrayWithObject:@"public.utf8-plain-text"]] && pasteboard.string.length == 40)) {
        shouldOfferAPIChange = NO;
    }
    
    if (shouldOfferAPIChange){
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Possible API key detected in clipboard", @"") message:NSLocalizedString(@"Do you want to use this instead of the built-in ones?", @"") preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleDefault handler:^(id action){
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define OL_KITE_CI_DEPLOY_KEY @ STRINGIZE2(OL_KITE_CI_DEPLOY)
            [OLKitePrintSDK setAPIKey:OL_KITE_CI_DEPLOY_KEY withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
            
#ifdef OL_KITE_OFFER_APPLE_PAY
            [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
#endif
            
            OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets info:@{}];
            vc.userEmail = @"";
            vc.userPhone = @"";
            vc.delegate = self;
            [vc addCustomPhotoProviderWithCollections:@[[[CatsAssetCollectionDataSource alloc] init]] name:@"Cats" icon:[UIImage imageNamed:@"cat"]];
            [vc addCustomPhotoProviderWithCollections:@[[[DogsAssetCollectionDataSource alloc] init]] name:@"Dogs" icon:[UIImage imageNamed:@"dog"]];
            [self presentViewController:vc animated:YES completion:NULL];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [OLKitePrintSDK setAPIKey:pasteboard.string withEnvironment:[self environment]];
            
#ifdef OL_KITE_OFFER_APPLE_PAY
            [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
            [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
#endif
            
            OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
            vc.userEmail = @"";
            vc.userPhone = @"";
            vc.delegate = self;
            [self presentViewController:vc animated:YES completion:NULL];
            
            //Register for push notifications
            NSUInteger types = (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
                [[UIApplication sharedApplication] registerUserNotificationSettings:
                 [UIUserNotificationSettings settingsForTypes:types categories:nil]];
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
            //    else {
            //        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
            //    }
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes and use staging", @"") style:UIAlertActionStyleDefault handler:^(id action){
            [OLKitePrintSDK setUseStaging:YES];
            [OLKitePrintSDK setAPIKey:pasteboard.string withEnvironment:[self environment]];
            
#ifdef OL_KITE_OFFER_APPLE_PAY
            [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
            [OLKitePrintSDK setApplePayPayToString:kApplePayBusinessName];
#endif
            
            OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
            vc.userEmail = @"";
            vc.userPhone = @"";
            vc.delegate = self;
            [vc addCustomPhotoProviderWithCollections:@[[[CatsAssetCollectionDataSource alloc] init]] name:@"Cats" icon:[UIImage imageNamed:@"cat"]];
            [vc addCustomPhotoProviderWithCollections:@[[[DogsAssetCollectionDataSource alloc] init]] name:@"Dogs" icon:[UIImage imageNamed:@"dog"]];
            [self presentViewController:vc animated:YES completion:NULL];
        }]];
        [self presentViewController:ac animated:YES completion:NULL];
    }
    else{
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define OL_KITE_CI_DEPLOY_KEY @ STRINGIZE2(OL_KITE_CI_DEPLOY)
        [OLKitePrintSDK setAPIKey:OL_KITE_CI_DEPLOY_KEY withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
        
#ifdef OL_KITE_OFFER_APPLE_PAY
        [OLKitePrintSDK setApplePayMerchantID:kApplePayMerchantIDKey];
#endif
        
        OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
        vc.userEmail = @"";
        vc.userPhone = @"";
        vc.delegate = self;
        [vc addCustomPhotoProviderWithCollections:@[[[CatsAssetCollectionDataSource alloc] init]] name:@"Cats" icon:[UIImage imageNamed:@"cat"]];
        [vc addCustomPhotoProviderWithCollections:@[[[DogsAssetCollectionDataSource alloc] init]] name:@"Dogs" icon:[UIImage imageNamed:@"dog"]];
        [self presentViewController:vc animated:YES completion:NULL];
    }
}

@end
