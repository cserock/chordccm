//
// REFrostedViewController.m
// REFrostedViewController
//
// Copyright (c) 2013 Roman Efimov (https://github.com/romaonthego)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "REFrostedViewController.h"
#import "REFrostedContainerViewController.h"
#import "UIImage+REFrostedViewController.h"
#import "UIView+REFrostedViewController.h"
#import "UIViewController+REFrostedViewController.h"
#import "RECommonFunctions.h"

#import <MessageUI/MessageUI.h>
#import "UIView+Toast.h"
#import <KakaoOpenSDK/KakaoOpenSDK.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import <sys/sysctl.h>
#import <FBSDKShareKit/FBSDKSharing.h>
#import <FBSDKShareKit/FBSDKShareDialog.h>
#import <FBSDKShareKit/FBSDKShareLinkContent.h>

@interface REFrostedViewController () <MFMailComposeViewControllerDelegate, FBSDKSharingDelegate>

@property (assign, readwrite, nonatomic) CGFloat imageViewWidth;
@property (strong, readwrite, nonatomic) UIImage *image;
@property (strong, readwrite, nonatomic) UIImageView *imageView;
@property (assign, readwrite, nonatomic) BOOL visible;
@property (strong, readwrite, nonatomic) REFrostedContainerViewController *containerViewController;
@property (strong, readwrite, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (assign, readwrite, nonatomic) BOOL automaticSize;
@property (assign, readwrite, nonatomic) CGSize calculatedMenuViewSize;
@property (nonatomic, retain) NSMutableDictionary* kakaoTalkLinkObjects;

@end

@implementation REFrostedViewController

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.wantsFullScreenLayout = YES;
#pragma clang diagnostic pop
    _panGestureEnabled = YES;
    _animationDuration = 0.35f;
    _backgroundFadeAmount = 0.3f;
    _blurTintColor = REUIKitIsFlatMode() ? nil : [UIColor colorWithWhite:1 alpha:0.75f];
    _blurSaturationDeltaFactor = 1.8f;
    _blurRadius = 10.0f;
    _containerViewController = [[REFrostedContainerViewController alloc] init];
    _containerViewController.frostedViewController = self;
    _menuViewSize = CGSizeZero;
    _liveBlur = REUIKitIsFlatMode();
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:_containerViewController action:@selector(panGestureRecognized:)];
    _automaticSize = YES;
}

- (id)initWithContentViewController:(UIViewController *)contentViewController menuViewController:(UIViewController *)menuViewController
{
    self = [self init];
    if (self) {
        _contentViewController = contentViewController;
        _menuViewController = menuViewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self re_displayController:self.contentViewController frame:self.view.bounds];
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.contentViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.contentViewController;
}

#pragma mark -
#pragma mark Setters

- (void)setContentViewController:(UIViewController *)contentViewController
{
    if (!_contentViewController) {
        _contentViewController = contentViewController;
        return;
    }
    
    [_contentViewController removeFromParentViewController];
    [_contentViewController.view removeFromSuperview];
    
    if (contentViewController) {
        [self addChildViewController:contentViewController];
        contentViewController.view.frame = self.containerViewController.view.frame;
        [self.view insertSubview:contentViewController.view atIndex:0];
        [contentViewController didMoveToParentViewController:self];
    }
    _contentViewController = contentViewController;
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

- (void)setMenuViewController:(UIViewController *)menuViewController
{
    if (!_menuViewController) {
        _menuViewController = menuViewController;
        return;
    }
    CGRect frame = _menuViewController.view.frame;
    [_menuViewController willMoveToParentViewController:nil];
    [_menuViewController removeFromParentViewController];
    [_menuViewController.view removeFromSuperview];
    _menuViewController = menuViewController;
    if (!_menuViewController)
        return;
    
    [self.containerViewController addChildViewController:menuViewController];
    menuViewController.view.frame = frame;
    [self.containerViewController.containerView addSubview:menuViewController.view];
    [menuViewController didMoveToParentViewController:self];
}

- (void)setMenuViewSize:(CGSize)menuViewSize
{
    _menuViewSize = menuViewSize;
    self.automaticSize = NO;
}

#pragma mark -

- (void)presentMenuViewController
{
    [self presentMenuViewControllerWithAnimatedApperance:YES];
}

- (void)presentMenuViewControllerWithAnimatedApperance:(BOOL)animateApperance
{
    
    float leftMenuMargin = 50.0f;
    
    if([self isPad]){
        leftMenuMargin = 450.0f;
    }
    
    if ([self.delegate conformsToProtocol:@protocol(REFrostedViewControllerDelegate)] && [self.delegate respondsToSelector:@selector(frostedViewController:willShowMenuViewController:)]) {
        [self.delegate frostedViewController:self willShowMenuViewController:self.menuViewController];
    }
    
    self.containerViewController.animateApperance = animateApperance;
    if (self.automaticSize) {
        if (self.direction == REFrostedViewControllerDirectionLeft || self.direction == REFrostedViewControllerDirectionRight)
            self.calculatedMenuViewSize = CGSizeMake(self.contentViewController.view.frame.size.width - leftMenuMargin, self.contentViewController.view.frame.size.height);
        
        if (self.direction == REFrostedViewControllerDirectionTop || self.direction == REFrostedViewControllerDirectionBottom)
            self.calculatedMenuViewSize = CGSizeMake(self.contentViewController.view.frame.size.width, self.contentViewController.view.frame.size.height - 50.0f);
    } else {
        self.calculatedMenuViewSize = CGSizeMake(_menuViewSize.width > 0 ? _menuViewSize.width : self.contentViewController.view.frame.size.width,
                                                 _menuViewSize.height > 0 ? _menuViewSize.height : self.contentViewController.view.frame.size.height);
    }
    
    if (!self.liveBlur) {
        if (REUIKitIsFlatMode() && !self.blurTintColor) {
            self.blurTintColor = [UIColor colorWithWhite:1 alpha:0.75f];
        }
        self.containerViewController.screenshotImage = [[self.contentViewController.view re_screenshot] re_applyBlurWithRadius:self.blurRadius tintColor:self.blurTintColor saturationDeltaFactor:self.blurSaturationDeltaFactor maskImage:nil];
    }
        
    [self re_displayController:self.containerViewController frame:self.contentViewController.view.frame];
    self.visible = YES;
}

- (void)hideMenuViewControllerWithCompletionHandler:(void(^)(void))completionHandler
{
    if (!self.liveBlur) {
        self.containerViewController.screenshotImage = [[self.contentViewController.view re_screenshot] re_applyBlurWithRadius:self.blurRadius tintColor:self.blurTintColor saturationDeltaFactor:self.blurSaturationDeltaFactor maskImage:nil];
        [self.containerViewController refreshBackgroundImage];
    }
    [self.containerViewController hideWithCompletionHandler:completionHandler];
}

- (void)resizeMenuViewControllerToSize:(CGSize)size
{
    if (!self.liveBlur) {
        self.containerViewController.screenshotImage = [[self.contentViewController.view re_screenshot] re_applyBlurWithRadius:self.blurRadius tintColor:self.blurTintColor saturationDeltaFactor:self.blurSaturationDeltaFactor maskImage:nil];
        [self.containerViewController refreshBackgroundImage];
    }
    [self.containerViewController resizeToSize:size];
}

- (void)hideMenuViewController
{
	[self hideMenuViewControllerWithCompletionHandler:nil];
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)recognizer
{
    if ([self.delegate conformsToProtocol:@protocol(REFrostedViewControllerDelegate)] && [self.delegate respondsToSelector:@selector(frostedViewController:didRecognizePanGesture:)])
        [self.delegate frostedViewController:self didRecognizePanGesture:recognizer];
    
    if (!self.panGestureEnabled)
        return;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self presentMenuViewControllerWithAnimatedApperance:NO];
    }
    
    [self.containerViewController panGestureRecognized:recognizer];
}

- (void) feedback {
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:self];
        
        UIDevice *device = [UIDevice currentDevice];
        
        NSString *deviceName = [self platformString];
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        NSString *systemVersion = device.systemVersion;
        
        NSString *emailSubject = [NSString stringWithFormat:@"[%@] 문의 및 피드백", [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"]];
        NSString *emailBody = [NSString stringWithFormat:@"\n\n------------\n빠른 지원을 위해 아래 내용을 지우거나 수정하지 말아주세요.\n- App Version : %@\n- Device : %@\n- OS : %@\n", appVersion, deviceName, systemVersion];
        
        [composeViewController setToRecipients:@[@"help@neosave.me"]];
        [composeViewController setSubject:emailSubject];
        [composeViewController setMessageBody:emailBody isHTML:NO];
        
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
    
}

- (void) inviteKakao {
    
    // app button type
    KakaoTalkLinkAction *iphoneAppAction = [KakaoTalkLinkAction createAppAction:KakaoTalkLinkActionOSPlatformIOS
                                                                     devicetype:KakaoTalkLinkActionDeviceTypePhone
                                                                      execparam:nil];
    
    KakaoTalkLinkAction *ipadAppAction = [KakaoTalkLinkAction createAppAction:KakaoTalkLinkActionOSPlatformIOS
                                                                   devicetype:KakaoTalkLinkActionDeviceTypePad
                                                                    execparam:nil];
    
    KakaoTalkLinkObject *buttonObj = [KakaoTalkLinkObject createAppButton:[[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"] actions:@[iphoneAppAction, ipadAppAction]];
    
    KakaoTalkLinkObject *label = [KakaoTalkLinkObject createLabel:@"수백 곡의 CCM을 손쉽게 코드를 바꿔 연주해 보세요."];
    
    if( [KOAppCall canOpenKakaoTalkAppLink]){
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"function"     // Event category (required)
                                                                  action:@"invite kakao"  // Event action (required)
                                                                   label:nil          // Event label
                                                                   value:nil] build]];    // Event value
        
        [KOAppCall openKakaoTalkAppLink:@[label, buttonObj]];
    }
}

- (void) inviteFB {
    
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://itunes.apple.com/app/id901633885?mt=8"];
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:self];
    
}


- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults :(NSDictionary*)results {
//    NSLog(@"FB: SHARE RESULTS=%@\n",[results debugDescription]);
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"function"     // Event category (required)
                                                          action:@"invite fb"  // Event action (required)
                                                           label:nil          // Event label
                                                           value:nil] build]];    // Event value
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
//    NSLog(@"FB: ERROR=%@\n",[error debugDescription]);
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"function"     // Event category (required)
                                                          action:@"error fb"  // Event action (required)
                                                           label:nil          // Event label
                                                           value:nil] build]];    // Event value

}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
//    NSLog(@"FB: CANCELED SHARER=%@\n",[sharer debugDescription]);
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"function"     // Event category (required)
                                                          action:@"cancel fb"  // Event action (required)
                                                           label:nil          // Event label
                                                           value:nil] build]];    // Event value
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

- (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

-(NSString *) platformString {
    NSString *platform = [self platform];
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}


#pragma mark -
#pragma mark Rotation handler

- (BOOL)shouldAutorotate
{
    return self.contentViewController.shouldAutorotate;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if ([self.delegate conformsToProtocol:@protocol(REFrostedViewControllerDelegate)] && [self.delegate respondsToSelector:@selector(frostedViewController:willAnimateRotationToInterfaceOrientation:duration:)])
        [self.delegate frostedViewController:self willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (self.visible) {
        if (self.automaticSize) {
            if (self.direction == REFrostedViewControllerDirectionLeft || self.direction == REFrostedViewControllerDirectionRight)
                self.calculatedMenuViewSize = CGSizeMake(self.view.bounds.size.width - 50.0f, self.view.bounds.size.height);
            
            if (self.direction == REFrostedViewControllerDirectionTop || self.direction == REFrostedViewControllerDirectionBottom)
                self.calculatedMenuViewSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height - 50.0f);
        } else {
            self.calculatedMenuViewSize = CGSizeMake(_menuViewSize.width > 0 ? _menuViewSize.width : self.view.bounds.size.width,
                                                     _menuViewSize.height > 0 ? _menuViewSize.height : self.view.bounds.size.height);
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (!self.visible) {
        self.calculatedMenuViewSize = CGSizeZero;
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    GAIDictionaryBuilder *gBuilder = nil;
   
    //Add an alert in case of failure
    switch (result)
    {
        case MFMailComposeResultCancelled:
            
            gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"function"     // Event category (required)
                                                              action:@"cancel feedback"  // Event action (required)
                                                               label:nil          // Event label
                                                               value:nil];
            
            break;
        case MFMailComposeResultSent:
            
            gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"function"     // Event category (required)
                                                              action:@"send feedback"  // Event action (required)
                                                               label:nil          // Event label
                                                               value:nil];
            
            [self.view makeToast:@"피드백 감사합니다.\n빠른 답변 드리겠습니다!"];
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            [self.view makeToast:@"피드백 발송이 실패했습니다."];
            break;
        default:
            break;
    }
    
    if(gBuilder){
        [tracker send:[gBuilder build]];    // Event value
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) isPad {
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 30200)
    if ([[UIDevice currentDevice] respondsToSelector: @selector(userInterfaceIdiom)])
        return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
#endif
    return NO;
}

- (void) goReview {
    UIAlertController * alert =   [UIAlertController
                                   alertControllerWithTitle:NSLocalizedString(@"Reviews",nil)
                                   message:NSLocalizedString(@"Please review this app in the Appstore.",nil)
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* later = [UIAlertAction
                            actionWithTitle:NSLocalizedString(@"Later",nil)
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action)
                            {
                                [alert dismissViewControllerAnimated:YES completion:nil];
                            }];
    
    UIAlertAction* confirm = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Review",nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                  NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=901633885&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"];
                                  [[UIApplication sharedApplication] openURL:url];
                                  
                              }];
    
    [alert addAction:later];
    [alert addAction:confirm];
    
    [self presentViewController:alert animated:YES completion:nil];
}
@end
