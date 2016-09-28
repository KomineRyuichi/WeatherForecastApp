//
//  APICommunication.h
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/09.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <Foundation/Foundation.h>

#if NS_BLOCKS_AVAILABLE
typedef void (^CallBackHandler)(NSDictionary *result, BOOL offlineFlag, BOOL apiFlag);
#endif
/**
 APIとの通信を行うクラス
 */
@interface APICommunication : NSObject
#if NS_BLOCKS_AVAILABLE
- (void)startAPICommunication :(NSString *)resource :(double)latitude :(double)longitude :(CallBackHandler)handler;
#endif

- (void)stopAPICommunication;
@end
