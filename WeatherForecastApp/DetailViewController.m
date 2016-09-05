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

@end

@implementation DetailCell1

@end

@interface DetailCell2 : UITableViewCell

@end

@implementation DetailCell2

@end

@interface DetailCell3 : UITableViewCell

@end

@implementation DetailCell3

@end

@interface ForecastCell : UITableViewCell

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
    return nil;
}

@end
