//
//  OpenShareManager.m
//  OpenShare_2
//
//  Created by jia on 16/5/3.
//  Copyright © 2016年 Jia. All rights reserved.
//

#import "OpenShareManager.h"
#import "OpenShareHeader.h"
#import "UIWindow+TCHelper.h"
#import "TCHTTPRequestCenter.h"
#import "OSPlatformController.h"
#import "OSResponse.h"
#import "SVProgressHUD.h"
#import "UIImage+SDYHelper.h"
#import "UIView+TCHelper.h"
#import "UIView+FindFirstResponder.h"
#import "ScreenCaptureManager.h"

@interface OpenShareManager () <OSPlatformControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>
{
    @private
    __weak id _shareFinishObsvr;
    
}

@property (nonatomic, strong) UIViewController *topMostCtrler;
@property (nonatomic, strong) OSPlatformController *platformCtrler;
@property (nonatomic, assign) OSPlatformCode platform;
@property (nonatomic, strong) OSMessage *message;
@property (nonatomic, copy) OSShareCompletionHandle shareCompletionHandle;
@property (nonatomic, weak) id firstResponder;

@end

@implementation OpenShareManager

+ (instancetype)defaultManager
{
    static OpenShareManager *mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self alloc] init];
    });
    
    return mgr;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_shareFinishObsvr];
}

- (id)init
{
    if (self = [super init]) {
        __weak typeof(self) wSelf = self;
        _shareFinishObsvr = [[NSNotificationCenter defaultCenter] addObserverForName:kOSShareFinishedNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            NSObject<OSResponse> *response = note.object;
            [wSelf callShareCompletionHandle:nil == response.error ? kOSStateSuccess : kOSStateFail error:response.error];
        }];
    }
    return self;
}

- (BOOL)shareMsg:(OSMessage *)msg platformCodes:(NSArray<NSNumber/*OSPlatformCode*/ *> *)codes completion:(OSShareCompletionHandle)completion
{
    NSArray *validCodes = [self.class validPlatformCodes:codes];
    if (validCodes.count < 1) {
        return NO;
    }
    
    _message = msg;
    _shareCompletionHandle = completion;
    _platformCtrler = [[OSPlatformController alloc] initWithPlatformCodes:validCodes screenShot:[UIImage imageWithData:ScreenCaptureManager.manger.screenShot] fullScreen:NO];
    _platformCtrler.delegate = self;
    _platformCtrler.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (nil != _message.dataItem.imageUrl || nil != _message.dataItem.thumbnailUrl) {
        [self downloadImage];
    } else {
        [self showPlatformController];
    }
    
    return YES;
}

- (BOOL)shareScreenShotMsg:(OSMessage *)msg platformCodes:(NSArray<NSNumber/*OSPlatformCode*/ *> *)codes completion:(OSShareCompletionHandle)completion
{
    NSArray *validCodes = [self.class validPlatformCodes:codes];
    if (validCodes.count < 1) {
        return NO;
    }
    
    _message = msg;
    _shareCompletionHandle = completion;
    _platformCtrler = [[OSPlatformController alloc] initWithPlatformCodes:validCodes screenShot:[UIImage imageWithData:msg.dataItem.imageData] fullScreen:YES];
    _platformCtrler.delegate = self;
    _platformCtrler.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self showPlatformController];
    
    return YES;
}

+ (NSArray<NSNumber/*OSPlatformCode*/ *> *)validPlatformCodes:(NSArray<NSNumber/*OSPlatformCode*/ *> *)codes
{
    if (codes.count < 1) {
        return codes;
    }
    
    NSMutableArray *arry = codes.mutableCopy;;
    
    NSNumber *qq = @(kOSPlatformQQ);
    NSNumber *qqzone = @(kOSPlatformQQZone);
    if (([arry containsObject:qq] || [arry containsObject:qqzone]) && !OpenShare.isQQInstalled) {
        [arry removeObject:qq];
        [arry removeObject:qqzone];
    }
    
    NSNumber *wxs = @(kOSPlatformWXSession);
    NSNumber *wxt = @(kOSPlatformWXTimeLine);
    if (([arry containsObject:wxs] || [arry containsObject:wxt]) && !OpenShare.isWeixinInstalled) {
        [arry removeObject:wxs];
        [arry removeObject:wxt];
    }
    
    NSNumber *sinawb = @(kOSPlatformSina);
    if ([arry containsObject:wxs] && !OpenShare.isSinaWeiboInstalled) {
        [arry removeObject:sinawb];
    }
    
    NSNumber *fb = @(kOSPlatformFacebook);
    if ([arry containsObject:fb] && !OpenShare.isFacebookInstalled) {
        [arry removeObject:fb];
    }
    
    NSNumber *tw = @(kOSPlatformTwitter);
    if ([arry containsObject:tw] && !OpenShare.isTwitterInstalled) {
        [arry removeObject:tw];
    }
    
    if (!MFMessageComposeViewController.canSendText) {
        [arry removeObject:@(kOSPlatformSms)];
    }
    
    return arry.count > 0 ? (arry.count == codes.count ? codes : arry) : nil;
}


#pragma mark - OSPlatformControllerDelegate

- (void)OSPlatformController:(OSPlatformController *)ctrler didSelectPlatformItem:(OSPlatformItem *)platform popoverRect:(CGRect)rect
{
//    [self dismissPlatformController];
    
    if (nil != _uiDelegate && [_uiDelegate respondsToSelector:@selector(platformController:didSelectPlatformItem:message:popoverRect:)]) {
        [_uiDelegate platformController:ctrler didSelectPlatformItem:platform message:_message popoverRect:rect];
    }
    _platform = platform.code;
    
    switch (platform.code) {
        case kOSPlatformQQ: {
            [OpenShare shareToQQ:_message];
            break;
        }
        case kOSPlatformQQZone: {
            [OpenShare shareToQQZone:_message];
            break;
        }
        case kOSPlatformWXSession: {
            [OpenShare shareToWeixinSession:_message];
            break;
        }
        case kOSPlatformWXTimeLine: {
            [OpenShare shareToWeixinTimeLine:_message];
            break;
        }
        case kOSPlatformSina: {
            [OpenShare shareToSinaWeibo:_message];
            break;
        }
        case kOSPlatformEmail: {
            [OpenShare shareToMail:_message delegate:self presentingCtrler:ctrler];
            break;
        }
        case kOSPlatformSms: {
            [OpenShare shareToSms:_message delegate:self presentingCtrler:ctrler];
            break;
        }
        case kOSPlatformCopyUrl : {
            NSParameterAssert(nil != _message.dataItem.copyableContent);
            if (nil != _message.dataItem.copyableContent) {
                [UIPasteboard generalPasteboard].string = _message.dataItem.copyableContent;
                _platform = kOSPlatformCopyUrl;
                [self callShareCompletionHandle:kOSStateSuccess error:nil];
            }
            
            break;
        }
        case kOSPlatformFacebook: {
            [OpenShare shareToFacebook:_message];
            break;
        }
        case kOSPlatformTwitter: {
            [OpenShare shareToTwitter:_message];
            break;
        }
        default:
            break;
    }
}

- (void)OSPlatformControllerWillDismiss:(OSPlatformController *)ctrler
{
    [self dismissPlatformController];
}


- (void)showPlatformController
{
    _topMostCtrler = [UIApplication sharedApplication].delegate.window.topMostViewController;
    _firstResponder = _topMostCtrler.view.findFirstResponder;
    [_firstResponder resignFirstResponder];
    
    if ([_topMostCtrler isKindOfClass:UIAlertController.class] || [_topMostCtrler isKindOfClass:UIActivityViewController.class]) {
        
        UIView *coverView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        coverView.backgroundColor = [UIColor whiteColor];
        [UIApplication.sharedApplication.delegate.window addSubview:coverView];
        
        UIAlertController *alertCtrler = (UIAlertController *)_topMostCtrler;
        __weak typeof(self) wSelf = self;
        [alertCtrler dismissViewControllerAnimated:NO completion:^{
            
            [coverView removeFromSuperview];
            
            UIViewController *ctrler = [UIApplication sharedApplication].delegate.window.topMostViewController;
            [ctrler presentViewController:wSelf.platformCtrler animated:YES completion:NULL];
        }];
        
    } else {
    
        [_topMostCtrler presentViewController:_platformCtrler animated:YES completion:NULL];
    }
}

- (void)dismissPlatformController
{
    __weak typeof(self) wSelf = self;
    [_platformCtrler dismissViewControllerAnimated:YES completion:^{
        if ([wSelf.topMostCtrler isKindOfClass:UIAlertController.class]
            || [wSelf.topMostCtrler isKindOfClass:UIActivityViewController.class]) {
            UIViewController *ctrler = UIApplication.sharedApplication.delegate.window.topMostViewController;
            [ctrler presentViewController:wSelf.topMostCtrler animated:YES completion:nil];
        } else {
            [wSelf.firstResponder becomeFirstResponder];
        }
    }];
}

- (void)downloadImage
{
    // thumbnailurl 和 imageurl 理论上是不共存的。如果都设置了的话，imageUrl 优先
    NSURL *url = nil != _message.dataItem.imageUrl ? _message.dataItem.imageUrl : _message.dataItem.thumbnailUrl;
    if (nil != url) {
        NSString *path = [[self.class defaultCacheDirectoryInDomain:@"OSImageCache" create:YES] URLByAppendingPathComponent:url.absoluteString.MD5_16].path;
        TCHTTPCachePolicy *policy = [[TCHTTPCachePolicy alloc] init];
        policy.cacheTimeoutInterval = kTCHTTPRequestCacheNeverExpired;
        policy.shouldExpiredCacheValid = NO;
        
        TCHTTPStreamPolicy *streamPolicy = [[TCHTTPStreamPolicy alloc] init];
        streamPolicy.shouldResumeDownload = YES;
        streamPolicy.downloadDestinationPath = path;
        
        __weak typeof(_message) wMessage = _message;
        id<TCHTTPRequest> request = [[TCHTTPRequestCenter defaultCenter] requestForDownload:url.absoluteString
                                                                               streamPolicy:streamPolicy
                                                                                cachePolicy:policy];
        if (nil != request) {
            request.timeoutInterval = 20.0f;
            request.observer = self;
            
            __weak typeof(self) wSelf = self;
            request.resultBlock = ^(id<TCHTTPRequest> request, BOOL success) {
                
                if (nil == wSelf) {
                    return;
                }

                NSData *data = nil;
                if (success) {
                    data = [NSData dataWithContentsOfFile:(NSString *)request.responseObject];
                    if (nil == wMessage.dataItem.imageUrl) {
                        @autoreleasepool {
                            UIImage *image = [UIImage imageWithData:data];
                            data = [image dataWithMaxCompressSizeBytes:50 * 1024];
                        }
                    }
                }
                
                if (nil != wSelf.uiDelegate && [wSelf.uiDelegate respondsToSelector:@selector(didDownloadImage)]) {
                    [wSelf.uiDelegate didDownloadImage];
                }
                
                if (nil != wMessage && wMessage == wSelf.message) {
                    
                    if (nil != data) {
                        if (nil != wMessage.dataItem.imageUrl) {
                            wMessage.dataItem.imageData = data;
                        } else {
                            wMessage.dataItem.thumbnailData = data;
                        }
                    }
                    
                    [wSelf showPlatformController];
                }
            };
            
            if ([request start:NULL]) {
                if (nil != wSelf.uiDelegate && [wSelf.uiDelegate respondsToSelector:@selector(willDownloadImage)]) {
                    [wSelf.uiDelegate willDownloadImage];
                }
            }
        }
    }
}


#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    NSError *error = nil;
    if (MessageComposeResultSent != result) {
        error = [NSError errorWithDomain:kOSErrorDomainSms
                                    code:result
                                userInfo:nil];
    }
    _platform = kOSPlatformSms;
    [self callShareCompletionHandle:nil == error ? kOSStateSuccess : kOSStateFail error:error];
}

- (void)cancel
{
    [self dismissPlatformController];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    _platform = kOSPlatformEmail;
    
    [self callShareCompletionHandle:nil == error ? kOSStateSuccess : kOSStateFail error:error];
}


#pragma mark -

- (void)callShareCompletionHandle:(OSShareState)state error:(NSError *)error
{
    // 消失
    // !!!: 短信和邮件不消失
    if (_platform != kOSPlatformEmail && _platform != kOSPlatformSms && nil == error) {
        [self dismissPlatformController];
    }
    
    if (nil != _shareCompletionHandle) {
        _shareCompletionHandle(_platform, _message, state, error);
        _shareCompletionHandle = nil;
    }
}

@end
