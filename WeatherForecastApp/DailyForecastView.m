//
//  DailyForecastView.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/06.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "DailyForecastView.h"

@implementation DailyForecastView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // 初期化
        UINib *nib = [UINib nibWithNibName:@"DailyForecastView" bundle:[NSBundle mainBundle]];
        NSArray *array = [nib instantiateWithOwner:self options:nil];
        self = [array objectAtIndex:0];
    }
    return self;
}

@end
