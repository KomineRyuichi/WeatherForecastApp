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

@end

@implementation DetailViewController

#pragma mark - ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"test");
    
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy/MM/dd";
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // タブバー隠す
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = YES;
    
    date = [NSDate date];
    NSLog(@"%@", date);
    
    self.dateLabel.text = [formatter stringFromDate:date];
    
    self.placeName = @"北海道";

    // 天気の詳細データを取得
    [self startAPICommunication:@"weather" :_detailLatitude :_detailLongitude];
    
    // 4日間の予報を取得
    [self startAPICommunication:@"forecast" :_detailLatitude :_detailLongitude];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Other

- (IBAction)addFavoritePlace:(UIBarButtonItem *)sender {
    
}

// 詳細情報を画面に配置
- (void)setDetailData:(NSDictionary *)detailData {
    // 天気アイコン
    self.weatherIcon.image = [UIImage imageNamed:@"Image"];
    
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

// 5日間の予報を画面に配置
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
        forecastView.weatherIcon.image = [UIImage imageNamed:@"Image"];
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
    // 緯度・経度サンプル(北海道)
    latitude = 43.06451;
    longitude = 141.346603;
    
    // URLの設定
    NSString *urlString = @"http://kominer:enimokR0150@api.openweathermap.org/data/2.5/";
    NSString *apiKey = @"43d013783f31afed676d9233f3caf08e";
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
            NSLog(@"Session Error:%@", error);
            return;
        }
        
        // JSONのパース
        NSLog(@"Parse");
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        
        if ([resource isEqualToString:@"weather"]) {
            // 天気の詳細データをUIに配置
            [self setDetailData:jsonData];
            
        } else if([resource isEqualToString:@"forecast"]) {
            // 4日間の予報データをUIに配置
            [self setForecasts:jsonData];
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


@end
