//
//  OSSinaParameter.m
//  OpenShare_2
//
//  Created by jia on 16/4/27.
//  Copyright © 2016年 Jia. All rights reserved.
//

#import "OSSinaParameter.h"
#import "OpenShareConfig.h"

@implementation OSSinaMediaObject

+ (TCMappingOption *)tc_mappingOption
{
    static TCMappingOption *opt = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        opt = [[TCMappingOption alloc] init];
        opt.nameCodingMapping = @{PropertySTR(desc): @"description"};
    });
    
    return opt;
}

@end

@implementation OSSinaParameter

@end

@implementation OSSinaApp

@end

@implementation OSSinaTransferObject

@end

@implementation OSSinaResponse

- (BOOL)isAuth
{
    return [_transferObject.__class isEqualToString:@"WBAuthorizeResponse"];
}

- (BOOL)isShare
{
    return [_transferObject.__class isEqualToString:@"WBSendMessageToWeiboResponse"];
}

- (NSError *)error
{
    NSError *error = nil;
    if (0 != _transferObject.statusCode) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: @"Share Failed.",
                                   NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@", @(_transferObject.statusCode)]};
        error = [NSError errorWithDomain:kOSErrorDomainSina
                                    code:_transferObject.statusCode
                                userInfo:userInfo];
    }
    return error;
}

@end
