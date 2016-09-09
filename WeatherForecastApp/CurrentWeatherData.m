//
//  CurrentWeatherData.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/09.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "CurrentWeatherData.h"

@implementation CurrentWeatherData

static CurrentWeatherData *currentWeatherData=nil;

+ (CurrentWeatherData *)getInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentWeatherData = [[CurrentWeatherData alloc] init];
    });
    
    return currentWeatherData;
}

- (void)setJsonData:(NSDictionary *)jsonData {
    // 天気アイコン名
    self.iconName = [[[jsonData objectForKey:@"weather"] objectAtIndex:0] objectForKey:@"icon" ];
    
    // 気温、湿度、気圧情報(レスポンスのKey:mainに入っている)
    NSDictionary *main = [NSDictionary dictionaryWithDictionary:[jsonData objectForKey:@"main"]];
    // 平均気温
    self.averageTemperature = [[main objectForKey:@"temp"] doubleValue];
    // 最高気温
    self.highTemperature = [[main objectForKey:@"temp_max"] doubleValue];
    // 最低気温
    self.lowTemperature = [[main objectForKey:@"temp_min"] doubleValue];
    
    // 湿度
    self.humidity = [[main objectForKey:@"humidity"] doubleValue];
    
    // 気圧
    self.pressure = [[main objectForKey:@"pressure"] doubleValue];
    
    // 風向き、風速情報(レスポンスのKey:windに入っている)
    NSDictionary *wind = [NSDictionary dictionaryWithDictionary:[jsonData objectForKey:@"wind"]];
    // 風向き
    self.windAngle = [[wind objectForKey:@"deg"] intValue];

    // 風速
    self.windSpeed = [[wind objectForKey:@"speed"] doubleValue];
}

@end
