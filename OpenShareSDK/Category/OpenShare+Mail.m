//
//  OpenShare+Mail.m
//  OpenShare_2
//
//  Created by jia on 16/5/3.
//  Copyright © 2016年 Jia. All rights reserved.
//

#import "OpenShare+Mail.h"
#import "OpenShare+Helper.h"
#import "UIWindow+TCHelper.h"

@implementation OpenShare (Mail)

+ (void)shareToMail:(OSMessage *)msg delegate:(id<MFMailComposeViewControllerDelegate>)delegate presentingCtrler:(UIViewController *)ctrler
{
    if (MFMailComposeViewController.canSendMail) {
        msg.dataItem.platformCode = kOSPlatformEmail;
        
        MFMailComposeViewController *mailComposeCtrler = [[MFMailComposeViewController alloc] init];
        mailComposeCtrler.mailComposeDelegate = delegate;
        [mailComposeCtrler setToRecipients:msg.dataItem.toRecipients];
        [mailComposeCtrler setCcRecipients:msg.dataItem.ccRecipients];
        mailComposeCtrler.subject = msg.dataItem.emailSubject;
        [mailComposeCtrler setMessageBody:msg.dataItem.emailBody isHTML:YES];
        
        if (nil != msg.dataItem.attachment) {
            [mailComposeCtrler addAttachmentData:msg.dataItem.attachment mimeType:msg.dataItem.attachmentMimeType fileName:msg.dataItem.attachmentFileName];
        }
        
        [ctrler presentViewController:mailComposeCtrler animated:YES completion:NULL];
        
    } else {
        msg.dataItem.platformCode = kOSPlatformEmail;
        
        NSMutableString *email = [NSMutableString stringWithString:@"mailto:"];
        if (msg.dataItem.toRecipients.count > 0) {
            [email appendFormat:@"%@?", [msg.dataItem.toRecipients componentsJoinedByString:@","]];
        } else {
            [email appendString:@"?"];
        }
        
        if (msg.dataItem.ccRecipients.count > 0) {
            [email appendFormat:@"cc=%@", [msg.dataItem.ccRecipients componentsJoinedByString:@","]];
        }
        
        if (nil != msg.dataItem.emailSubject) {
            [email appendString:[NSString stringWithFormat:@"&subject=%@", msg.dataItem.emailSubject]];
        }
        if (nil != msg.dataItem.emailBody) {
            [email appendString:[NSString stringWithFormat:@"&body=%@", msg.dataItem.emailBody]];
        }
        
        NSString *url = [email stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
        if (nil == url) {
            return;
        }
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
    }
}

@end
