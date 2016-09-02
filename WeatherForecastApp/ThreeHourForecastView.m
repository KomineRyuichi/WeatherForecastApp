//
//  ThreeHourForecastView.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/02.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "ThreeHourForecastView.h"

@implementation ThreeHourForecastView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UINib *nib = [UINib nibWithNibName:@"ThreeHourForecastView" bundle:[NSBundle mainBundle]];
        NSArray *array = [nib instantiateWithOwner:self options:nil];
        self = [array objectAtIndex:0];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
