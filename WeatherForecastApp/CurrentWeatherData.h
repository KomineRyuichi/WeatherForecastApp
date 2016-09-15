//
//  CurrentWeatherData.h
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/09.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 JSONデータで取得した天気情報を管理するクラス
 */
@interface CurrentWeatherData : NSObject

@property (nonnull) NSString *iconName;
@property double averageTemperature;
@property double highTemperature;
@property double lowTemperature;
@property double humidity;
@property double pressure;
@property int windAngle;
@property double windSpeed;
@property BOOL apiRegulationsFlag;

+ (nonnull CurrentWeatherData *)getInstance;

- (void)setJsonData:(nonnull NSDictionary *)jsonData;

@end
