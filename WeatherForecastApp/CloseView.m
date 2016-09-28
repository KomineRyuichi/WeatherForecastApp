//
//  CloseView.m
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/28.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "CloseView.h"

@implementation CloseView

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.target performSelector:self.action withObject:self afterDelay:0.0f];
}


@end
