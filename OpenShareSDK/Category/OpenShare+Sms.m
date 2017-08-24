//
//  OpenShare+Sms.m
//  OpenShare_2
//
//  Created by jia on 16/5/3.
//  Copyright © 2016年 Jia. All rights reserved.
//

#import "OpenShare+Sms.h"
#import "OpenShare+Helper.h"
#import "UIWindow+TCHelper.h"

@implementation OpenShare (Sms)

+ (void)shareToSms:(OSMessage *)msg delegate:(id<MFMessageComposeViewControllerDelegate>)delegate presentingCtrler:(UIViewController *)ctrler
{
    if (MFMessageComposeViewController.canSendText) {
        msg.dataItem.platformCode = kOSPlatformSms;
        
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        controller.recipients = msg.dataItem.recipients;
        controller.body = msg.dataItem.msgBody;
        controller.messageComposeDelegate = delegate;
        
        if (nil != msg.dataItem.attachment) {
            [controller addAttachmentData:msg.dataItem.attachment
                           typeIdentifier:@"public.data"
                                 filename:msg.dataItem.attachmentFileName];
        }
        
        [ctrler presentViewController:controller animated:YES completion:NULL];
    }
}

@end
