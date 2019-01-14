//
//  UIImage+OSHelper.h
//  
//
//  Created by jia on 16/11/1.
//  Copyright © 2016年 jia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (OSHelper)

/**
 *  压缩图片到指定文件大小
 *
 *  @param bytes  目标大小（最大值）
 *
 *  @return 返回的图片文件
 */
- (NSData *)dataWithMaxCompressSizeBytes:(NSUInteger)bytes;

@end
