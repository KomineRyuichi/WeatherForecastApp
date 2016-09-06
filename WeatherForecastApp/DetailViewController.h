//
//  DetailViewController.h
//  WeatherForecastApp
//
//  Created by Komine Ryuichi on 2016/09/04.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController
@property (nonatomic) double detailLatitude;
@property (nonatomic) double detailLongitude;
@property (nonatomic) NSString *placeName;

@end
