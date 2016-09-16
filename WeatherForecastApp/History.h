//
//  History.h
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/16.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface History : NSManagedObject

@property (nullable, nonatomic, retain) NSString *placeName;
@property (nullable, nonatomic, retain) NSNumber *placeLatitude;
@property (nullable, nonatomic, retain) NSNumber *placeLongitude;
@property (nullable, nonatomic, retain) NSDate *date;

@end

NS_ASSUME_NONNULL_END
