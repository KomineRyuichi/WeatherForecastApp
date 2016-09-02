//
//  ThreeHourForecastView.h
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/02.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThreeHourForecastView : UIView
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *precipitationLabel;
@end
