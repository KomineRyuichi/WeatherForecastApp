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
#import "DailyForecastView.h"

@interface DetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *weatherIcon;
@property (weak, nonatomic) IBOutlet UILabel *placeNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *temperatureIcon;
@property (weak, nonatomic) IBOutlet UILabel *averageTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *highTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowTemperatureLabel;
@property (weak, nonatomic) IBOutlet UIImageView *humidityIcon;
@property (weak, nonatomic) IBOutlet UILabel *humidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *pressureLabel;
@property (weak, nonatomic) IBOutlet UIImageView *windAngleIcon;
@property (weak, nonatomic) IBOutlet UILabel *windAngleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *windSpeedIcon;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *dailyForecasts;

@end

@implementation DetailViewController

#pragma mark - ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"test");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // タブバー隠す
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = YES;

    // 天気アイコン
    self.weatherIcon.image = [UIImage imageNamed:@"Image"];
    
    // 気温アイコン
    self.temperatureIcon.image = [UIImage imageNamed:@"Image"];
    
    // 湿度アイコン
    self.humidityIcon.image = [UIImage imageNamed:@"Image"];
    
    // 風向きアイコン
    self.windAngleIcon.image = [UIImage imageNamed:@"Image"];

    // 風速アイコン
    self.windSpeedIcon.image = [UIImage imageNamed:@"Image"];
    
    // Scrol Viewの設定
    // コンテンツサイズの設定(横スクロールのため、Width * ページ数)
    self.dailyForecasts.contentSize = CGSizeMake(170*5, 245);
    
    // ページ数分ループ
    for(int i=0; i<5; i++) {
        DailyForecastView *forecastView = [[DailyForecastView alloc] init];
        // フレームサイズ
        forecastView.frame = CGRectMake(170*i, 0.0, 170, 245);
        // 日付
        forecastView.dateLabel.text = @"09/05";
        // 天気アイコン
        forecastView.weatherIcon.image = [UIImage imageNamed:@"Image"];
        // 気温
        forecastView.temperatureLabel.text = @"30℃";
        // 降水量
        forecastView.precipitationLabel.text = @"0ml";
        // 湿度
        forecastView.humidityLabel.text = @"60%";
        // スクロールビューに追加
        [self.dailyForecasts addSubview:forecastView];
        // 参照破棄
        forecastView = nil;
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Other

- (IBAction)addFavoritePlace:(UIBarButtonItem *)sender {
    
}

@end
