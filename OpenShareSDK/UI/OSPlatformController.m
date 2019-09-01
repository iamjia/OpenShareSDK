//
//  OSPlatformController.m
//  OpenShare_2
//
//  Created by jia on 16/5/3.
//  Copyright © 2016年 Jia. All rights reserved.
//

#import "OSPlatformController.h"
#import "OpenShare.h"
#import "ScreenCaptureManager.h"
#import "TCKit.h"
#import "PresentAnimator.h"
#import "DismissAnimator.h"
#import "UIColor+TCUtilities.h"

static NSString *const kCell = @"cell";
static NSInteger const kContentBtnTag = 1024;
static CGFloat const kAnimDuration = 0.35f;

@interface OSPlatformController () <UICollectionViewDataSource, UICollectionViewDelegate
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
, CAAnimationDelegate
#endif
, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) NSMutableArray *platforms;
@end

@implementation OSPlatformController {
@private
    UICollectionView *_collectionView;
    NSDictionary *_platformConfig;
    UIView *_containerView;
    UIView *_touchView;
    UIButton *_cancelBtn;
    
    UIImage *_screenShot;
    UIImageView *_previewImageView;
    UIImageView *_backgroundView;
    
    BOOL _shouldAnimate;
    BOOL _fullScreen;
}

- (NSBundle *)openShareBundle
{
    static dispatch_once_t onceToken;
    static NSBundle *bundle = nil;
    dispatch_once(&onceToken, ^{
        NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"OpenShareResources" withExtension:@"bundle"];
        if (nil != url) {
            bundle = [NSBundle bundleWithURL:url];
        }
    });
    return bundle;
}

- (UIImage *)snsImageNamed:(NSString *)name
{
    return [UIImage imageNamed:name inBundle:self.openShareBundle compatibleWithTraitCollection:nil];
}

- (NSDictionary *)platformConfig
{
    if (nil == _platformConfig) {
        _platformConfig = @{@(kOSPlatformQQ): @{@"name": @"os.platform.qq",
                                                @"image": @"os_qq_icon.png"},
                            @(kOSPlatformQQZone): @{@"name": @"os.platform.qzone",
                                                    @"image": @"os_qzone_icon.png"},
                            @(kOSPlatformWXSession): @{@"name": @"os.platform.wxsession",
                                                       @"image": @"os_wechat_icon.png"},
                            @(kOSPlatformWXTimeLine): @{@"name": @"os.platform.wxtimeline",
                                                        @"image": @"os_wechat_timeline_icon.png"},
                            @(kOSPlatformSina): @{@"name": @"os.platform.sina",
                                                  @"image": @"os_sina_icon.png"},
                            @(kOSPlatformEmail): @{@"name": @"os.platform.email",
                                                   @"image": @"os_email_icon.png"},
                            @(kOSPlatformSms): @{@"name": @"os.platform.sms",
                                                 @"image": @"os_sms_icon.png"},
                            @(kOSPlatformCopyUrl): @{@"name": @"os.platform.copyurl",
                                                     @"image": @"os_copy_url"},
                            @(kOSPlatformFacebook): @{@"name": @"os.platform.facebook",
                                                      @"image": @"os_fb_icon"},
                            @(kOSPlatformTwitter): @{@"name": @"os.platform.twitter",
                                                     @"image": @"os_tw_icon"},
                            @(kOSPlatformSystem): @{@"name": @"os.platform.system",
                                                    @"image": @"os_sys_icon"},};
    }
    return _platformConfig;
}

- (UIImageView *)previewImageView
{
    if (nil == _previewImageView) {
        _previewImageView = [[UIImageView alloc] init];
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        _previewImageView.image = _screenShot;
    }
    return _previewImageView;
}

- (CGFloat)containerViewViewHeight
{
    return _containerView.frame.size.height;
}

- (instancetype)initWithPlatformCodes:(NSArray<NSNumber *> *)codes screenShot:(UIImage *)screenShot fullScreen:(BOOL)fullScreen
{
    if (self = [super init]) {
        _screenShot = screenShot;
        _fullScreen = fullScreen;
        
        if (nil == _platforms) {
            _platforms = NSMutableArray.array;
        }
        
        for (NSNumber *code in codes) {
            OSPlatformItem *platform = [[OSPlatformItem alloc] init];
            platform.displayName = NSLocalizedStringFromTableInBundle(self.platformConfig[code][@"name"], nil, self.openShareBundle, nil);
            platform.displayIcon = [self snsImageNamed:self.platformConfig[code][@"image"]];
            platform.code = code.integerValue;
            [_platforms addObject:platform];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    self.transitioningDelegate = self;
    
    CGRect bounds = self.view.bounds;
    _backgroundView = [[UIImageView alloc] initWithFrame:bounds];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backgroundView.image = _fullScreen ? _screenShot.blurImage : _screenShot;
    [self.view addSubview:_backgroundView];
    
    _touchView = [[UIView alloc] initWithFrame:bounds];
    _touchView.backgroundColor = _fullScreen ? UIColor.clearColor : [UIColor colorWithWhite:0 alpha:0.5f];
    _touchView.hidden = YES;
    _touchView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDismiss)];
    [_touchView addGestureRecognizer:tapGes];
    [self.view addSubview:_touchView];
    
    static CGFloat const spacing = 2.0f;
    static CGFloat const cancelBtnHeight = 49.0f;
    
    CGFloat itemWidth = UIScreen.mainScreen.bounds.size.width > 320.0f ? 90.0f : 77.0f;
    CGFloat separatorLineHeight = [UIView pointWithPixel:1.0f];
    CGFloat maxNumberOfItemsInRow = floor(UIScreen.mainScreen.bounds.size.width / itemWidth);
    NSInteger row = (NSInteger)ceil(_platforms.count / maxNumberOfItemsInRow);
    CGFloat collectionViewHeight = row * itemWidth + (row + 1) * spacing;
    
    CGRect rect = bounds;
    rect.size.height = collectionViewHeight + separatorLineHeight + cancelBtnHeight;
    rect.origin.y = bounds.size.height - rect.size.height;
    
    _containerView = [[UIView alloc] initWithFrame:rect];
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_containerView];
    
    if (_fullScreen) {
        self.previewImageView.frame = CGRectMake(0.0f, 10.0f, bounds.size.width, rect.origin.y - 15.0f);
        _previewImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_touchView addSubview:_previewImageView];
    }
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = spacing;
    layout.minimumInteritemSpacing = spacing;
    layout.sectionInset = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
    layout.itemSize = (CGSize){.width = itemWidth, .height = itemWidth};
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, bounds.size.width, collectionViewHeight) collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;

    if (@available(iOS 13, *)) {
        _collectionView.backgroundColor = UIColor.tertiarySystemBackgroundColor;
    } else {
        _collectionView.backgroundColor = UIColor.whiteColor;
    }
    
    [_collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:kCell];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [_containerView addSubview:_collectionView];
    
    UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetMaxY(_collectionView.frame), bounds.size.width, separatorLineHeight)];

    if (@available(iOS 13, *)) {
        separatorLine.backgroundColor = UIColor.separatorColor;
    } else {
        separatorLine.backgroundColor = RGBHex(0xdcdcdc);
    }
    separatorLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [_containerView addSubview:separatorLine];
    
    _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelBtn.backgroundColor = _collectionView.backgroundColor;
    [_cancelBtn setTitleColor:[UIColor colorWithLight:RGBHex(0x333333) dark:UIColor.whiteColor] forState:UIControlStateNormal];
    
    NSString *cancelTitle = NSLocalizedStringFromTableInBundle(@"public.button.cancel", nil, self.openShareBundle, nil);
    [_cancelBtn setTitle:cancelTitle forState:UIControlStateNormal];
    _cancelBtn.frame = CGRectMake(0.0f, CGRectGetMaxY(separatorLine.frame), bounds.size.width, cancelBtnHeight);
    _cancelBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [_cancelBtn addTarget:self action:@selector(tapDismiss) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_cancelBtn];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 禁止present界面dismiss的时候触发这些操作
    _shouldAnimate = nil == self.presentedViewController;
    
    ScreenCaptureManager.manger.ignoreNotification = YES;
    if (_fullScreen && nil != _screenShot && !UIApplication.sharedApplication.isStatusBarHidden) {
        self.prefersStatusBarHidden = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    // 禁止邮件或者短信界面dismiss的时候触发这些操作
    if (_shouldAnimate) {
        [self show];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    // 禁止邮件或者短信界面dismiss的时候触发这些操作
//    if (_shouldAnimate) {
//        [self show];
//    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    ScreenCaptureManager.manger.ignoreNotification = NO;
    if (_fullScreen && nil != _screenShot) {
        self.prefersStatusBarHidden = NO;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return [super prefersStatusBarHidden];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _platforms.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCell forIndexPath:indexPath];
    UIButton *contentBtn = [cell.contentView viewWithTag:kContentBtnTag];
    if (nil == contentBtn) {
        contentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        contentBtn.frame = cell.bounds;
        contentBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentBtn.tag = 1024;
        contentBtn.userInteractionEnabled = NO;
        contentBtn.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        contentBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        contentBtn.titleLabel.minimumScaleFactor = 0.8;
        [contentBtn setTitleColor:[UIColor colorWithLight:UIColor.blackColor dark:UIColor.whiteColor] forState:UIControlStateNormal];
        contentBtn.paddingBetweenTitleAndImage = 5.0f;
        contentBtn.layoutStyle = kTCButtonLayoutStyleImageTopTitleBottom;
        [cell.contentView addSubview:contentBtn];
    }
    
    OSPlatformItem *platform = _platforms[indexPath.item];
    [contentBtn setTitle:platform.displayName forState:UIControlStateNormal];
    [contentBtn setImage:platform.displayIcon forState:UIControlStateNormal];
    
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    CGRect rect = [collectionView convertRect:cell.frame toView:self.view];
    
    if (nil != _screenShot) {
        if (nil != self.delegate && [self.delegate respondsToSelector:@selector(OSPlatformController:didSelectPlatformItem:popoverRect:)]) {
            [self.delegate OSPlatformController:self didSelectPlatformItem:self.platforms[indexPath.item] popoverRect:rect];
        }
    } else {
        if (nil != self.delegate && [self.delegate respondsToSelector:@selector(OSPlatformController:didSelectPlatformItem:popoverRect:)]) {
            [self.delegate OSPlatformController:self didSelectPlatformItem:self.platforms[indexPath.item] popoverRect:rect];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tapDismiss
{
    if (nil != self.delegate && [self.delegate respondsToSelector:@selector(OSPlatformControllerWillDismiss:)]) {
        [self.delegate OSPlatformControllerWillDismiss:self];
    }
}

- (void)show
{
    CATransition *animation = [CATransition animation];
    animation.duration = kAnimDuration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionMoveIn;
    animation.subtype = kCATransitionFromTop;
    animation.removedOnCompletion = YES;
    [_containerView.layer addAnimation:animation forKey:nil];
    
    CATransition *hiddenAnim = [CATransition animation];
    hiddenAnim.type = kCATransitionReveal;
    hiddenAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    hiddenAnim.duration = kAnimDuration;
    hiddenAnim.removedOnCompletion = YES;
    [_touchView.layer addAnimation:hiddenAnim forKey:nil];
    _touchView.hidden = NO;
    
    CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnim.fromValue = @(0.2f);
    scaleAnim.toValue = @(1.0f);
    scaleAnim.duration = kAnimDuration;
    scaleAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    scaleAnim.removedOnCompletion = NO;
    scaleAnim.fillMode = kCAFillModeForwards;
    [_previewImageView.layer addAnimation:scaleAnim forKey:nil];
}

- (void)dismiss:(void(^)(void))completion
{
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = kAnimDuration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.type = kCATransitionReveal;
    animation.subtype = kCATransitionFromBottom;
    animation.removedOnCompletion = YES;
    [animation setValue:completion forKey:@"finishBlock"];
    [_containerView.layer addAnimation:animation forKey:nil];
    _containerView.hidden = YES;
    
    CATransition *hiddenAnim = [CATransition animation];
    hiddenAnim.type = kCATransitionFade;
    hiddenAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    hiddenAnim.duration = kAnimDuration;
    hiddenAnim.removedOnCompletion = YES;
    [_touchView.layer addAnimation:hiddenAnim forKey:nil];
    _touchView.hidden = YES;
}

- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[PresentAnimator alloc] init];
}

- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[DismissAnimator alloc] init];
}


#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    void(^completion)(void) = [anim valueForKey:@"finishBlock"];
    if (nil != completion) {
        completion();
    }
}

@end

@implementation OSPlatformItem

@end
