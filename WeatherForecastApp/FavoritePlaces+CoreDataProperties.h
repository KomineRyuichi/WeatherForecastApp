//
//  FavoritePlaces+CoreDataProperties.h
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/05.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "FavoritePlaces.h"

NS_ASSUME_NONNULL_BEGIN

@interface FavoritePlaces (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *placeName;
@property (nullable, nonatomic, retain) NSNumber *placeLatitude;
@property (nullable, nonatomic, retain) NSNumber *placeLongitude;
@property (nullable, nonatomic, retain) NSNumber *placeOrder;

@end

NS_ASSUME_NONNULL_END
