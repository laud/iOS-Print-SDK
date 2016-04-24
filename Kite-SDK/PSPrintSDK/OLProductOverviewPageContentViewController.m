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

#import "OLProductOverviewPageContentViewController.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLProductOverviewViewController.h"
#import "OLPersonalizedProductPhotos.h"

@interface OLProduct (Private)

-(void)setCoverImageToImageView:(UIImageView *)imageView;
-(void)setProductPhotography:(NSUInteger)i toImageView:(UIImageView *)imageView;

@end

@interface OLProductOverviewViewController (Private)

- (IBAction)onButtonStartClicked:(UIBarButtonItem *)sender;

@end

@interface OLProductOverviewPageContentViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation OLProductOverviewPageContentViewController

- (void)didReceiveMemoryWarning {
    [[OLPersonalizedProductPhotos sharedManager] clearCachedImages];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *identifer = self.product.productTemplate.identifier;
    [[OLPersonalizedProductPhotos sharedManager] productImageForProductIdentifier:identifer
                                                                            index:self.pageIndex
                                                                 withCustomImages:self.userSelectedPhotos
                                                                     completion:^(UIImage *image) {
                                                                         if (image) {
                                                                             [OLPersonalizedProductPhotos setAndFadeImage:image toImageView:self.imageView];
                                                                         } else {
                                                                             NSUInteger index = [[OLPersonalizedProductPhotos sharedManager] remappedIndexForProductIdentifier:identifer originalIndex:self.pageIndex];
                                                                             [self.product setProductPhotography:index toImageView:self.imageView];
                                                                         }
                                                                     }];
    
}

- (IBAction)userDidTapOnImage:(UITapGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(userDidTapOnImage)]){
        [self.delegate userDidTapOnImage];
    }
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}


@end
