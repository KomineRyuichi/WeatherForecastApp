//
//  DailyForecastView.h
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/06.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DailyForecastView :UIView
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *weatherIcon;
@property (weak, nonatomic) IBOutlet UIImageView *temperatureIcon;
@property (weak, nonatomic) IBOutlet UIImageView *precipitationIcon;
@property (weak, nonatomic) IBOutlet UIImageView *humidityIcon;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *precipitationLabel;
@property (weak, nonatomic) IBOutlet UILabel *humidityLabel;

@end
