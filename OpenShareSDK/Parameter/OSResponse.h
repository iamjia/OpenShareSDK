//
//  OSResponse.h

//
//  Created by jia on 16/5/17.
//  Copyright © 2016年 jia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenShareConfig.h"

@protocol OSResponse <NSObject>

@required
- (NSError *)error;

@end
