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
#import "CurrentWeatherData.h"
#import "APICommunication.h"
#import <QuartzCore/QuartzCore.h>

@interface DetailViewController () {
    NSDateFormatter *formatter;
    NSDate *date;
    UIAlertController *networkAlertController;
    UIAlertController *apiAlertController;
    UIView *loadingView;
    CurrentWeatherData *currentWeatherData;
    APICommunication *apiCommunication;
}

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
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIView *view1;
@property (weak, nonatomic) IBOutlet UIView *view2;
@property (weak, nonatomic) IBOutlet UIView *view3;

@end

@implementation DetailViewController

#pragma mark - ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy/MM/dd";
    
    AppDelegate *appDelegate = [UIApplication.sharedApplication delegate];
    self.context = [appDelegate managedObjectContext];
    
    networkAlertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"オフラインです。" preferredStyle:UIAlertControllerStyleAlert];
    
    apiAlertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"API規制です。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
    
    [networkAlertController addAction:action];
    [apiAlertController addAction:action];
    
    // OFFの画像設定
    [self.favoriteButton setImage:[UIImage imageNamed:@"NonFavorite"] forState:UIControlStateNormal];
    
    // ONの画像設定
    [self.favoriteButton setImage:[UIImage imageNamed:@"AddFavorite"] forState:UIControlStateSelected];
    
    // 読み込み中暗転用ビュー
    loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
    loadingView.backgroundColor = [UIColor blackColor];
    loadingView.alpha = 0.5f;
    
    currentWeatherData = [CurrentWeatherData getInstance];
    
    // 各ラベル初期設定
    // 平均気温
    self.averageTemperatureLabel.text = @"℃";
    // 湿度
    self.humidityLabel.text = @"%";
    // 気圧
    self.pressureLabel.text = @"hPa";
    // 風速
    self.windSpeedLabel.text = @"m/s";
    
    // 天気アイコン以外の各アイコンの設定
    // 気温アイコン
    self.temperatureIcon.image = [UIImage imageNamed:@"temperature"];
    // 湿度アイコン
    self.humidityIcon.image = [UIImage imageNamed:@"humidity"];
    // 風向きアイコン
    self.windAngleIcon.image = [UIImage imageNamed:@"wind"];
    // 風速アイコン
    self.windSpeedIcon.image = [UIImage imageNamed:@"wind speed"];
    //viewに枠線を設定
    _view1.layer.borderColor = [UIColor blackColor].CGColor;
    _view1.layer.borderWidth = 0.5f;
    _view2.layer.borderColor = [UIColor blackColor].CGColor;
    _view2.layer.borderWidth = 0.5f;
    _view3.layer.borderColor = [UIColor blackColor].CGColor;
    _view3.layer.borderWidth = 0.5f;
    
    apiCommunication = [[APICommunication alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // タブバー隠す
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = YES;
    
    date = [NSDate date];
    
    // 今日の日付表示
    self.dateLabel.text = [formatter stringFromDate:date];
    
    // 地名
    self.placeNameLabel.text = _placeName;
    
    [self searchFavoritePlace:_placeName];

    [self.indicator startAnimating];
    [self.view addSubview:loadingView];
    [self.view bringSubviewToFront:_indicator];
    
    [apiCommunication startAPICommunication:@"weather" :_detailLatitude :_detailLongitude :^(NSDictionary *result, BOOL networkOfflineFlag, BOOL apiRegulationFlag) {
        
        if(networkOfflineFlag || apiRegulationFlag) {
            [self stopIndicator];
            if(networkOfflineFlag) {
                [self alertNetworkError];
            } else if (apiRegulationFlag) {
                [self alertAPIError];
            }
        } else {
            [currentWeatherData setJsonData:result];
            [self setDetailData];
            [apiCommunication startAPICommunication:@"forecast" :_detailLatitude :_detailLongitude :^(NSDictionary *result, BOOL networkOfflineFlag, BOOL apiRegulationFlag) {
                if(networkOfflineFlag || apiRegulationFlag) {
                    if(networkOfflineFlag) {
                        [self alertNetworkError];
                    } else if (apiRegulationFlag) {
                        [self alertAPIError];
                    }
                } else {
                    [self setForecasts:result];
                }
            }];
            [self stopIndicator];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Other

- (void) stopIndicator {
    [self.indicator stopAnimating];
    [loadingView removeFromSuperview];
}

- (IBAction)addFavoritePlace:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    if(sender.selected) {
        [self registerPlaceToCoreData];
    } else {
        [self deleteFavoritePlace];
    }
    
}

// 詳細情報を画面に配置
- (void)setDetailData {
    // 天気アイコン
    self.weatherIcon.image = [UIImage imageNamed:currentWeatherData.iconName];
    
    // 平均気温
    self.averageTemperatureLabel.text = [NSString stringWithFormat:@"%2.0f℃", currentWeatherData.averageTemperature];
    // 最高気温
    self.highTemperatureLabel.text = [NSString stringWithFormat:@"%2.0f", currentWeatherData.highTemperature];
    // 最低気温
    self.lowTemperatureLabel.text = [NSString stringWithFormat:@"%2.0f", currentWeatherData.lowTemperature];
    
    // 湿度
    self.humidityLabel.text = [NSString stringWithFormat:@"%2.0f%%", currentWeatherData.humidity];
    
    // 気圧
    self.pressureLabel.text = [NSString stringWithFormat:@"%4.1fhPa", currentWeatherData.pressure];
    
    // 風向き
    self.windAngleLabel.text = [self windDecision:currentWeatherData.windAngle];
    
    // 風速
    self.windSpeedLabel.text = [NSString stringWithFormat:@"%1.0fm/s", currentWeatherData.windSpeed];
}

// 4日間の予報を画面に配置
- (void)setForecasts:(NSDictionary *)forecastData {
    // Scrol Viewの設定
    // コンテンツサイズの設定(横スクロールのため、Width * ページ数:4)
    self.dailyForecasts.contentSize = CGSizeMake(170*4, 245);
    double temperature;
    double humidity;
    double precipitation;
    
    // ページ数分ループ
    for(int i=0, j=10; i<4; i++, j=j+8) {
        NSArray *list = [NSArray arrayWithArray:[forecastData objectForKey:@"list"]];
        NSDictionary *weatherData = [NSDictionary dictionaryWithDictionary:[list objectAtIndex:j]];
        DailyForecastView *forecastView = [[DailyForecastView alloc] init];
        //viewに枠線を設定
        forecastView.view4.layer.borderColor = [UIColor blackColor].CGColor;
        forecastView.view4.layer.borderWidth = 0.5f;
        forecastView.view5.layer.borderColor = [UIColor blackColor].CGColor;
        forecastView.view5.layer.borderWidth = 0.5f;
        forecastView.view6.layer.borderColor = [UIColor blackColor].CGColor;
        forecastView.view6.layer.borderWidth = 0.5f;
        // フレームサイズ
        forecastView.frame = CGRectMake(170*i, 0.0, 170, self.dailyForecasts.frame.size.height);
        // 日付
        NSString *forecastDate = [[weatherData objectForKey:@"dt_txt"] substringWithRange:NSMakeRange(5, 5)];
        forecastView.dateLabel.text = [forecastDate stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
        // 天気アイコン
        forecastView.weatherIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [[[weatherData objectForKey:@"weather"] objectAtIndex:0] objectForKey:@"icon" ]]];
        // 気温
        temperature = [[[weatherData objectForKey:@"main"] objectForKey:@"temp"] doubleValue];
        forecastView.temperatureLabel.text = [NSString stringWithFormat:@"%2.1f℃", temperature];
        // 気温アイコン
        forecastView.temperatureIcon.image = [UIImage imageNamed:@"temperature"];
        // 降水量
        precipitation = [[[weatherData objectForKey:@"rain"] objectForKey:@"3h" ] doubleValue];
        forecastView.precipitationLabel.text = [NSString stringWithFormat:@"%1.0fml", precipitation];
        // 降水量アイコン
        forecastView.precipitationIcon.image = [UIImage imageNamed:@"precipitation"];
        // 湿度
        humidity = [[[weatherData objectForKey:@"main"] objectForKey:@"humidity"] doubleValue];
        forecastView.humidityLabel.text = [NSString stringWithFormat:@"%2.1f%%", humidity];
        // 湿度アイコン
        forecastView.humidityIcon.image = [UIImage imageNamed:@"humidity"];
        // スクロールビューに追加
        [self.dailyForecasts addSubview:forecastView];
        // 参照破棄
        forecastView = nil;
    }
}



- (NSString *)windDecision:(int)angle {
    
    if(angle == 0) {
        return @"無風";
    } else if(angle > 0 && angle < 90) {
        return @"北東の風";
    } else if(angle == 90) {
        return @"東風";
    } else if(angle > 90 && angle < 180) {
        return @"南東の風";
    } else if(angle == 180) {
        return @"南風";
    } else if(angle > 180 && angle < 270) {
        return @"南西の風";
    } else if(angle == 270) {
        return @"西風";
    } else if(angle > 270 && angle < 360) {
        return @"北西の風";
    } else {
        return @"北風";
    }
    
}

#pragma mark - CoreData

- (void)registerPlaceToCoreData {
    FavoritePlaces *newPlace = [NSEntityDescription insertNewObjectForEntityForName:@"FavoritePlaces" inManagedObjectContext:self.context];
    
    newPlace.placeName = _placeName;
    newPlace.placeLatitude = [NSNumber numberWithDouble:_detailLatitude];
    newPlace.placeLongitude = [NSNumber numberWithDouble:_detailLongitude];
    newPlace.placeOrder = [NSNumber numberWithInteger:0];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"placeOrder" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSArray *results = [self.context executeFetchRequest:fetchRequest error:nil];
    
    for (int i=0; i<[results count] -1; i++) {
        FavoritePlaces *place = [results objectAtIndex:i];
        NSInteger beforeOrder = [place.placeOrder integerValue];
        place.placeOrder = [NSNumber numberWithInteger:beforeOrder + 1];
    }
    
    NSError *error = nil;
    if(![self.context save:&error]) {
#if DEBUG
        NSLog(@"Error:%@", error);
#endif
    }
}

- (void)deleteFavoritePlace {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"placeName=%@", _placeName];
    [fetchRequest setPredicate:predicate];
    
    NSArray *results = [self.context executeFetchRequest:fetchRequest error:nil];
    
    FavoritePlaces *place = [results objectAtIndex:0];
    [self.context deleteObject:place];
    
    NSError *error = nil;
    if(![self.context save:&error]) {
#if DEBUG
        NSLog(@"Error:%@", error);
#endif
    }
}

- (void)alertNetworkError {
    UIViewController *baseView = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (baseView.presentedViewController != nil && !baseView.presentedViewController.isBeingDismissed) {
        baseView = baseView.presentedViewController;
    }
    [baseView presentViewController:networkAlertController animated:YES completion:nil];
}

- (void)alertAPIError {
    UIViewController *baseView = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (baseView.presentedViewController != nil && !baseView.presentedViewController.isBeingDismissed) {
        baseView = baseView.presentedViewController;
    }
    [baseView presentViewController:apiAlertController animated:YES completion:nil];
}

- (void)searchFavoritePlace:(NSString *)placeName {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    
    // 一度に読み込むサイズを指定します。
    [fetchRequest setFetchLimit:20];
    
    // 検索結果をplaceOrderの昇順にする。
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"placeOrder" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"placeName = %@", placeName];
    [fetchRequest setPredicate:predicate];
    
    // NSFetchedResultsController(結果を持ってくるクラス)の生成
    NSFetchedResultsController *fetchedResultsController
    = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                          managedObjectContext:self.context
                                            sectionNameKeyPath:nil
                                                     cacheName:nil];
    
    // データ検索
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
#if DEBUG
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#endif
    }
    
    if([[fetchedResultsController fetchedObjects] count] > 0) {
        self.favoriteButton.selected = YES;
    }
}

@end
