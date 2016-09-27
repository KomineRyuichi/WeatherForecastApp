//
//  PlaceNameViewController.h
//  WeatherForecastApp
//
//  Created by 岩上遥平 on 2016/09/26.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlaceNameViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *placeNameTableView;
@property (nonatomic) void (^dataBlocks)(NSString *,NSNumber *,NSNumber *);

@end
