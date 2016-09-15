//
//  DetailViewController.h
//  WeatherForecastApp
//
//  Created by Komine Ryuichi on 2016/09/04.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>
/**
 当日の天気の詳細情報と翌日から4日間分の天気予報を表示する画面クラス
 */
@interface DetailViewController : UIViewController
@property (nonatomic) double detailLatitude;
@property (nonatomic) double detailLongitude;
@property (nonatomic) NSString *placeName;

@end
