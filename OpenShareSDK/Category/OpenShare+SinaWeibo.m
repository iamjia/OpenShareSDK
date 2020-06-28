//
//  OpenShare+SinaWeibo.m
//  OpenShare_2
//
//  Created by jia on 16/3/23.
//  Copyright © 2016年 Jia. All rights reserved.
//

#import "OpenShare+SinaWeibo.h"
#import "OSSinaParameter.h"
#import "NSObject+TCCoding.h"

@implementation OpenShare (SinaWeibo)

+ (BOOL)isSinaWeiboInstalled
{
    NSURLComponents *com = [[NSURLComponents alloc] init];
    com.scheme = kOSSinaScheme;
    return [self canOpenURL:com.URL];
}

+ (void)registSinaWeiboWithAppKey:(NSString *)appKey
{
    if (nil == appKey) {
        return;
    }
    [self registAppWithName:kOSSinaIdentifier
                       data:@{@"appKey": appKey}];
}

+ (void)shareToSinaWeibo:(OSMessage *)msg
{
    if ([self isAppRegisted:kOSSinaIdentifier]) {
        [self openAppWithURL:[self sinaUrlWithMessage:msg]];
    }
}

+ (NSURL *)sinaUrlWithMessage:(OSMessage *)msg
{
    OSSinaParameter *sinaParam = [[OSSinaParameter alloc] init];
    OSDataItem *data = msg.dataItem;
    data.platformCode = kOSPlatformSina;
    
    sinaParam.__class = @"WBMessageObject";
    sinaParam.text = data.sinaContent;
    if (nil != data.imageData) {
        sinaParam.imageObject = @{@"imageData": data.imageData};
    }
    
    OSSinaTransferObject *tfObj = [[OSSinaTransferObject alloc] init];
    tfObj.__class = @"WBSendMessageToWeiboRequest";
    tfObj.message = sinaParam.tc_plistObject;
    tfObj.requestID = TCAppInfo.uuidForDevice;
    
    OSPlatformAccount *account = [msg accountForApp:kOSSinaIdentifier];
    NSString *appId = account.appId;
    if (nil == appId) {
        appId = [self dataForRegistedApp:kOSSinaIdentifier][@"appKey"];
    }
    
    OSSinaApp *app = [[OSSinaApp alloc] init];
    app.appKey = appId;
    app.bundleID = TCAppInfo.bundleIdentifier;
    
    NSMutableArray *pbItems = nil;
    @try {
        NSData *transferObjectData = nil;
        NSData *appData = nil;
        if (@available(iOS 11, *)) {
            transferObjectData = [NSKeyedArchiver archivedDataWithRootObject:tfObj.tc_plistObject requiringSecureCoding:NO error:NULL];
            appData = [NSKeyedArchiver archivedDataWithRootObject:app.tc_plistObject requiringSecureCoding:NO error:NULL];
        } else {
            transferObjectData = [NSKeyedArchiver archivedDataWithRootObject:tfObj.tc_plistObject];
            appData = [NSKeyedArchiver archivedDataWithRootObject:app.tc_plistObject];
        }
        
        pbItems = NSMutableArray.array;
        if (nil != transferObjectData) {
            [pbItems addObject:@{PropertySTR(transferObject): transferObjectData}];
        }
        if (nil != appData) {
            [pbItems addObject:@{PropertySTR(app): appData}];
        }
        
        NSData *userInfoData = nil;
        if (@available(iOS 11, *)) {
            userInfoData = [NSKeyedArchiver archivedDataWithRootObject:@{} requiringSecureCoding:NO error:NULL];
        } else {
            userInfoData = [NSKeyedArchiver archivedDataWithRootObject:@{}];
        }
        
        [pbItems addObject:@{PropertySTR(userInfo): userInfoData}];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
        pbItems = nil;
    } @finally {
        if (nil != pbItems) {
            [UIPasteboard generalPasteboard].items = pbItems;
            
            
            NSURLComponents *com = [[NSURLComponents alloc] init];
            com.scheme = kOSSinaScheme;
            com.host = @"request";
            com.query = [NSString stringWithFormat:@"id=%@&sdkversion=003013000", TCAppInfo.uuidForDevice];
            
            return com.URL;
        }
        
        return nil;
    }
}

+ (BOOL)wb_handleOpenURL:(NSURL *)url
{
    if (![url.scheme hasPrefix:kOSSinaIdentifier]) {
        return NO;
    }
    
    NSMutableDictionary *responseDic = nil;
    @try {
        NSArray *items = UIPasteboard.generalPasteboard.items;
        responseDic = [NSMutableDictionary dictionaryWithCapacity:items.count];
        
        for (NSDictionary *item in items) {
            for (NSString *key in item) {
                NSString *value = nil;
                if ([key isEqualToString:@"sdkversion"]) {
                    value = [[NSString alloc] initWithData:item[key] encoding:NSUTF8StringEncoding];
                } else {
                    if (@available(iOS 11, *)) {
                        value = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:NSString.class, NSDictionary.class, NSArray.class, NSNumber.class, NSData.class, nil] fromData:item[key] error:NULL];
                    } else {
                        value = [NSKeyedUnarchiver unarchiveObjectWithData:item[key]];
                    }
                }
                if (nil != value) {
                    responseDic[key] = value;
                }
            }
        }
        
    } @catch (NSException *exception) {
        DLog_e(@"%@", exception);
        responseDic = nil;
        
    } @finally {
        // 清空微博存的数据
        UIPasteboard.generalPasteboard.items = @[];
        if ([url.absoluteString rangeOfString:self.identifier].location == NSNotFound) {
            return YES;
        }
        self.identifier = nil;
        
        if (responseDic.count > 0) {
            OSSinaResponse *response = [OSSinaResponse tc_mappingWithDictionary:responseDic];
            if (response.isAuth) {
                // auth
            } else if (response.isShare) {
                // 分享回调
                [[NSNotificationCenter defaultCenter] postNotificationName:kOSShareFinishedNotification object:response];
            }
        }
        
        return YES;
    }
}

@end
