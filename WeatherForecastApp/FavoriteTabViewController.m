//
//  FavoriteTabViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/01.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "FavoriteTabViewController.h"
#import "ThreeHourForecastView.h"

@interface WeatherSummaryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *todayWeatherIconImage;
@property (weak, nonatomic) IBOutlet UILabel *placeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UIButton *cellExpansionButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end

@implementation WeatherSummaryCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.temperatureLabel.text = @"　℃";

    self.scrollView.hidden = YES;
}

@end

@interface FavoriteTabViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *weatherData;
    NSMutableArray *forecastData;
    NSArray *forecastViewArray;
    NSMutableArray *favoritePlaceNames;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation FavoriteTabViewController

#pragma mark - ViewController

// 読み込み直後の処理
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    ThreeHourForecastView *forecastView1 = [[ThreeHourForecastView alloc] init];
    ThreeHourForecastView *forecastView2 = [[ThreeHourForecastView alloc] init];
    ThreeHourForecastView *forecastView3 = [[ThreeHourForecastView alloc] init];
    ThreeHourForecastView *forecastView4 = [[ThreeHourForecastView alloc] init];
    ThreeHourForecastView *forecastView5 = [[ThreeHourForecastView alloc] init];
    ThreeHourForecastView *forecastView6 = [[ThreeHourForecastView alloc] init];
    
    forecastViewArray = [NSArray arrayWithObjects:forecastView1, forecastView2, forecastView3, forecastView4, forecastView5, forecastView6, nil];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    // セルの高さ設定
    self.tableView.estimatedRowHeight = 200.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    weatherData = [NSMutableArray array];
    forecastData = [NSMutableArray array];
    favoritePlaceNames = [NSMutableArray array];
    [favoritePlaceNames addObject:@"test"];
    [favoritePlaceNames addObject:@"tetete"];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.visibleViewController.navigationItem.title = @"お気に入り";
    self.navigationController.visibleViewController.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

// 画面表示直後の処理
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"Did Appearですよ〜〜〜〜〜〜〜〜");
    
    for(int i=0; i<[favoritePlaceNames count]; i++) {
        [self startAPICommunication:@"weather" :0.0 :0.0];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"Did Disappearですぞ〜〜〜〜〜〜〜〜〜");
    
    [weatherData removeAllObjects];
    [forecastData removeAllObjects];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// 遷移直前の処理
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}

#pragma mark - TableView

// 表示行数の設定
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [favoritePlaceNames count];
}

// 表示するセルの生成
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"WeatherSummaryCell";
    
    WeatherSummaryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if([weatherData count] > 0 && [favoritePlaceNames count] == [weatherData count]) {
        // 天気情報
        NSDictionary *weatherDatum = [NSDictionary dictionaryWithDictionary:[weatherData objectAtIndex:indexPath.row]];
    
        cell.temperatureLabel.text = [NSString stringWithFormat:@"%2.1f℃", [[[weatherDatum objectForKey:@"main"] objectForKey:@"temp"] doubleValue]];
        [cell.cellExpansionButton addTarget:self action:@selector(pushCellExpansionButton:event:) forControlEvents:UIControlEventTouchUpInside];

    }
    
    if([forecastData count] > 0) {
        // 3時間ごとの天気予報
        //cell.scrollView.hidden = NO;
        cell.scrollView.contentSize = CGSizeMake(100.0*6, 95.0);
        for(int i=0; i<6; i++) {
            ThreeHourForecastView *forecastView = [[ThreeHourForecastView alloc] init];
            forecastView.frame = CGRectMake(100.0*i, 10.0, 100.0, 95.0);
            NSDictionary *forecast = [NSDictionary dictionaryWithDictionary:[forecastData objectAtIndex:i]];
            forecastView.precipitationLabel.text = [NSString stringWithFormat:@"%2.1fmm", [[[forecast objectForKey:@"rain"] objectForKey:@"3h"] doubleValue]];
            [cell.scrollView addSubview:forecastView];
        }
        
    }
    
    cell.placeNameLabel.text = [favoritePlaceNames objectAtIndex:indexPath.row];
    
    //cell.scrollView.hidden = YES;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WeatherSummaryCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    float height = 80.0f;

    if(!cell.scrollView.hidden) {
        height = height + 120;
    }
    
    return height;
}

// 削除許可
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// 並び替え許可
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// 選択せる検知
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //[self.navigationController performSegueWithIdentifier:@"goDetail" sender:self];
}

// セル削除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

// セルの並び替え
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
}

// 編集スタイル
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.tableView.editing ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

#pragma mark - Other

// 拡張ボタンアクション
- (void)pushCellExpansionButton:(UIButton *)sender event:(UIEvent *)event {
    NSIndexPath *indexPath = [self indexPathForControlEvent:event];
    WeatherSummaryCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    cell.scrollView.hidden = !cell.scrollView.hidden;

    
    if(cell.scrollView.hidden) {
        [self.tableView reloadData];
    } else {
        [self startAPICommunication:@"forecast" :0.0 :0.0];
    }

}

// 編集モード切り替え
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    self.tableView.editing = editing;
}

// 押されたボタンの行番号を返す
- (NSIndexPath *)indexPathForControlEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    return indexPath;
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
    NSURL *url = [NSURL URLWithString:[test stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]; //[NSURL URLWithString:urlString];
    
    // Requestの設定
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    //[request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
    //NSLog(@"%@", [param dataUsingEncoding:NSUTF8StringEncoding]);
    // Session, SessionConfigの生成
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
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        
        if ([resource isEqualToString:@"weather"]) {
            // 天気情報を配列に追加
            [weatherData addObject:jsonData];
            
        } else if([resource isEqualToString:@"forecast"]) {
            // 3時間ごとの天気予報を取得
            for(int i=0; i<6; i++) {
                [forecastData addObject:[[jsonData objectForKey:@"list"] objectAtIndex:i]];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
 
    // タスクの実行
    [dataTask resume];
}

@end
