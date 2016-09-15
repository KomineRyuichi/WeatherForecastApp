//
//  CustomButton.h
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/14.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
/**
 マップ上のボタンを編集するためのクラス
 */
@interface CustomButton : UIButton

@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

@end
