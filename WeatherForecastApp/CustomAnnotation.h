//
//  CustomAnnotation.h
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/06.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface CustomAnnotation : NSObject <MKAnnotation>
@property (readwrite, nonatomic) CLLocationCoordinate2D coordinate;
@property (readwrite, nonatomic, copy) NSString* title;
@property (readwrite, nonatomic, copy) NSString* subtitle;
@end
