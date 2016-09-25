//
//  TimeTableViewCell.h
//  WeatherForecastApp
//
//  Created by 岩上遥平 on 2016/09/26.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
