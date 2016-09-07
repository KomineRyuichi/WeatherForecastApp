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

@interface DetailViewController () {
    NSDateFormatter *formatter;
    NSDate *date;
    BOOL communicationDisableFlag;
    UIAlertController *networkAlertController;
    UIAlertController *apiAlertController;
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

@end

@implementation DetailViewController

#pragma mark - ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"test");
    
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy/MM/dd";
    
    AppDelegate *appDelegate = [UIApplication.sharedApplication delegate];
    self.context = [appDelegate managedObjectContext];
    
    networkAlertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"オフラインです。" preferredStyle:UIAlertControllerStyleAlert];
    
    apiAlertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"API規制です。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { communicationDisableFlag = YES;}];
    
    [networkAlertController addAction:action];
    [apiAlertController addAction:action];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // タブバー隠す
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = YES;
    
    date = [NSDate date];
    NSLog(@"%@", date);
    
    // 今日の日付表示
    self.dateLabel.text = [formatter stringFromDate:date];

    // 天気の詳細データを取得
    [self startAPICommunication:@"weather" :_detailLatitude :_detailLongitude];
    
    if(!communicationDisableFlag) {
        // 4日間の予報を取得
        [self startAPICommunication:@"forecast" :_detailLatitude :_detailLongitude];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Other

- (IBAction)addFavoritePlace:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    if(sender.selected) {
        sender.imageView.image = [UIImage imageNamed:@"AddFavorite"];
        [self registerPlaceToCoreData];
    } else {
        sender.imageView.image = [UIImage imageNamed:@"NonFavorite"];
        [self deleteFavoritePlace];
    }
    
}

// 詳細情報を画面に配置
- (void)setDetailData:(NSDictionary *)detailData {
    // 天気アイコン
    self.weatherIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [[[detailData objectForKey:@"weather"] objectAtIndex:0] objectForKey:@"icon" ]]];
    
    // 地名
    self.placeNameLabel.text = _placeName;

    // 気温、湿度、気圧情報(レスポンスのKey:mainに入っている)
    NSDictionary *main = [NSDictionary dictionaryWithDictionary:[detailData objectForKey:@"main"]];
    // 気温アイコン
    self.temperatureIcon.image = [UIImage imageNamed:@"Image"];
    // 平均気温
    self.averageTemperatureLabel.text = [NSString stringWithFormat:@"%2.1f℃", [[main objectForKey:@"temp"] doubleValue]];
    // 最高気温
    self.highTemperatureLabel.text = [NSString stringWithFormat:@"%2.0f", [[main objectForKey:@"temp_max"] doubleValue]];
    // 最低気温
    self.lowTemperatureLabel.text = [NSString stringWithFormat:@"%2.0f", [[main objectForKey:@"temp_min"] doubleValue]];
    
    // 湿度アイコン
    self.humidityIcon.image = [UIImage imageNamed:@"Image"];
    // 湿度
    self.humidityLabel.text = [NSString stringWithFormat:@"%2.0f%%", [[main objectForKey:@"humidity"] doubleValue]];
    
    // 気圧
    self.pressureLabel.text = [NSString stringWithFormat:@"%4.1fhPa", [[main objectForKey:@"pressure"] doubleValue]];
    
    // 風向き、風速情報(レスポンスのKey:windに入っている)
    NSDictionary *wind = [NSDictionary dictionaryWithDictionary:[detailData objectForKey:@"wind"]];
    // 風向きアイコン
    self.windAngleIcon.image = [UIImage imageNamed:@"Image"];
    // 風向き
    self.windAngleLabel.text = [self windDecision:[[wind objectForKey:@"deg"] intValue]];
    
    // 風速アイコン
    self.windSpeedIcon.image = [UIImage imageNamed:@"Image"];
    // 風速
    self.windSpeedLabel.text = [NSString stringWithFormat:@"%1.0fm/s", [[wind objectForKey:@"speed"] doubleValue]];
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
    for(int i=0, j=8; i<4; i++, j=j+8) {
        NSArray *list = [NSArray arrayWithArray:[forecastData objectForKey:@"list"]];
        NSDictionary *weatherData = [NSDictionary dictionaryWithDictionary:[list objectAtIndex:j]];
        DailyForecastView *forecastView = [[DailyForecastView alloc] init];
        // フレームサイズ
        forecastView.frame = CGRectMake(170*i, 0.0, 170, 245);
        // 日付
        forecastView.dateLabel.text = @"09/05";
        NSString *forecastDate = [[weatherData objectForKey:@"dt_txt"] substringWithRange:NSMakeRange(5, 5)];
        forecastView.dateLabel.text = [forecastDate stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
        // 天気アイコン
        forecastView.weatherIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [[[weatherData objectForKey:@"weather"] objectAtIndex:0] objectForKey:@"icon" ]]];
        // 気温
        temperature = [[[weatherData objectForKey:@"main"] objectForKey:@"temp"] doubleValue];
        forecastView.temperatureLabel.text = [NSString stringWithFormat:@"%2.1f℃", temperature];
        // 降水量
        precipitation = [[[weatherData objectForKey:@"rain"] objectForKey:@"3h" ] doubleValue];
        forecastView.precipitationLabel.text = [NSString stringWithFormat:@"%1.0fml", precipitation];
        // 湿度
        humidity = [[[weatherData objectForKey:@"main"] objectForKey:@"humidity"] doubleValue];
        forecastView.humidityLabel.text = [NSString stringWithFormat:@"%2.1f%%", humidity];
        // スクロールビューに追加
        [self.dailyForecasts addSubview:forecastView];
        // 参照破棄
        forecastView = nil;
    }
}

// API通信開始
- (void)startAPICommunication:(NSString *)resource :(double)latitude :(double)longitude{
    // URLの設定
    NSString *urlString = @"http://kominer:enimokR0150@api.openweathermap.org/data/2.5/";
    NSString *apiKey = @"54d51f13da00bdabafdee82cdee866ea";
    NSString *param = [NSString stringWithFormat:@"lat=%3.6lf&lon=%3.6lf&units=metric&appid=%@", latitude, longitude, apiKey];
    NSString *test = [NSString stringWithFormat:@"%@%@?%@", urlString, resource, param];
    NSURL *url = [NSURL URLWithString:[test stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    // Requestの設定
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    // DataTaskの生成
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        
        // エラー処理
        if(error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:networkAlertController animated:YES completion:nil];
            });
            NSLog(@"Session Error:%@", error);
            return;
        }
        
        // JSONのパース
        NSLog(@"Parse");
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        
        if([jsonData objectForKey:@"cod"] == [NSNumber numberWithInteger:401]) {
            [self presentViewController:apiAlertController animated:YES completion:nil];
        } else {
            if ([resource isEqualToString:@"weather"]) {
                // 天気の詳細データをUIに配置
                [self setDetailData:jsonData];
            
            } else if([resource isEqualToString:@"forecast"]) {
                // 4日間の予報データをUIに配置
                [self setForecasts:jsonData];
            }
        }
    }];
    
    // タスクの実行
    [dataTask resume];
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
        NSLog(@"Error:%@", error);
    } else {
        NSLog(@"Success");
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
        NSLog(@"Error:%@", error);
    } else {
        NSLog(@"Success");
    }
}

@end
