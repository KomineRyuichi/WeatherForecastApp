//
//  DetailViewController.m
//  WeatherForecastApp
//
//  Created by Komine Ryuichi on 2016/09/04.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "DetailViewController.h"
#import "FavoritePlaces.h"
#import "AppDelegate.h"

@interface DetailCell1 : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *placeNameLabel;

@end

@implementation DetailCell1

@end

@interface DetailCell2 : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *temperatureIcon;
@property (weak, nonatomic) IBOutlet UIImageView *humidityIcon;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *humidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureHighLowLabel;
@property (weak, nonatomic) IBOutlet UILabel *pressureLabel;


@end

@implementation DetailCell2

@end

@interface DetailCell3 : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *windAngleIcon;
@property (weak, nonatomic) IBOutlet UIImageView *windSpeedIcon;
@property (weak, nonatomic) IBOutlet UILabel *windAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedLabel;

@end

@implementation DetailCell3

@end

@interface ForecastCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ForecastCell

@end

@interface DetailViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *detailTableView;
@property (weak, nonatomic) IBOutlet UITableView *forecastTableView;

@end

@implementation DetailViewController

#pragma mark - ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.detailTableView.delegate = self;
    self.detailTableView.dataSource = self;
    self.forecastTableView.delegate = self;
    self.forecastTableView.dataSource = self;
    
    self.detailTableView.estimatedRowHeight = 68;
    self.detailTableView.rowHeight = UITableViewAutomaticDimension;
    self.forecastTableView.estimatedRowHeight = 224;
    self.forecastTableView.rowHeight = UITableViewAutomaticDimension;
    
    NSLog(@"test");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(tableView == _detailTableView) {
        return 3;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(tableView == _detailTableView) {
        if(indexPath.row == 0) {
            DetailCell1 *cell = [self.detailTableView dequeueReusableCellWithIdentifier:@"DetailCell1"];
            
            cell.placeNameLabel.text = @"さいたま市";
            cell.icon.image = [UIImage imageNamed:@"Image"];
            return cell;
            
        } else if(indexPath.row == 1) {
            DetailCell2 *cell = [self.detailTableView dequeueReusableCellWithIdentifier:@"DetailCell2"];
            
            cell.humidityIcon.image =  [UIImage imageNamed:@"Image"];
            cell.humidityLabel.text = @"1029.3 hPa";
            cell.temperatureIcon.image =  [UIImage imageNamed:@"Image"];
            cell.temperatureLabel.text = @"30 ℃";
            cell.temperatureHighLowLabel.text = @"32 / 24 ℃";
            
            return cell;
        } else {
            DetailCell3 *cell = [self.detailTableView dequeueReusableCellWithIdentifier:@"DetailCell3"];
            cell.windAngleIcon.image =  [UIImage imageNamed:@"Image"];
            cell.windAngleLabel.text = @"北東の風";
            cell.windSpeedIcon.image =  [UIImage imageNamed:@"Image"];
            cell.windSpeedLabel.text = @"5 m/s";
            return cell;
        }
    } else {
        ForecastCell *cell = [self.forecastTableView dequeueReusableCellWithIdentifier:@"ForecastCell"];
        return cell;
    }
}

@end
