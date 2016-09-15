//
//  CustomButton.m
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/14.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "CustomButton.h"

@interface CustomButton ()

@end

@implementation CustomButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return self;
    _borderColor = [UIColor blackColor];
    _borderWidth = 0;
    _cornerRadius = 0;
    return self;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    self.layer.borderColor = _borderColor.CGColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    self.layer.borderWidth = _borderWidth;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
}

@end
