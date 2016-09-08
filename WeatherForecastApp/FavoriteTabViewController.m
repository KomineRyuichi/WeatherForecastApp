//
//  FavoriteTabViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/01.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "FavoriteTabViewController.h"
#import "ThreeHourForecastView.h"
#import "DetailViewController.h"
#import "AppDelegate.h"
#import "FavoritePlaces.h"

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
    [self.cellExpansionButton setImage:[UIImage imageNamed:@"open"] forState:UIControlStateNormal];
    [self.cellExpansionButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateSelected];
}

@end

@interface FavoriteTabViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *weatherData;
    NSMutableArray *forecastData;
    NSArray *forecastViewArray;
    NSMutableArray *favoritePlaces;
    NSString *selectedPlaceName;
    double selectedPlaceLatitude;
    double selectedPlaceLongitude;
    UIAlertController *networkAlertController;
    UIAlertController *apiAlertController;
    BOOL communicationDisableFlag;
    BOOL communicateAPIDisableFlag;
    NSInteger pageCount;
    UIView *loadingView;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addPlaceButton;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@end

@implementation FavoriteTabViewController

#pragma mark - ViewController

// 読み込み直後の処理
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    pageCount = 8;
    
    self.navigationController.visibleViewController.tabBarItem.image = [UIImage imageNamed:@"FavoriteTab"];
    self.navigationController.visibleViewController.tabBarItem.title = @"Favorite";
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    // セルの高さ設定
    self.tableView.estimatedRowHeight = 200.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    forecastData = [NSMutableArray array];
    favoritePlaces = [NSMutableArray array];
    
    AppDelegate *appDelegate = [UIApplication.sharedApplication delegate];
    self.context = [appDelegate managedObjectContext];
    
    networkAlertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"オフラインです。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
    
    apiAlertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"API規制です。" preferredStyle:UIAlertControllerStyleAlert];
    
    [networkAlertController addAction:action];
    [apiAlertController addAction:action];
    
    communicationDisableFlag = NO;
    communicateAPIDisableFlag = NO;
    
    loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
    loadingView.backgroundColor = [UIColor blackColor];
    loadingView.alpha = 0.5f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.visibleViewController.navigationItem.title = @"お気に入り";
    self.navigationController.visibleViewController.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = NO;
    
    [self getFavoritePlace];
    
    weatherData = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [favoritePlaces count]; i++)
    {
        [weatherData addObject:[NSDictionary dictionary]];
    }

    if([favoritePlaces count]  == 0) {
        [self.view bringSubviewToFront:_addPlaceButton];
    } else {
        [self.view sendSubviewToBack:_addPlaceButton];
    }
    
}

// 画面表示直後の処理
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.indicator startAnimating];
    [self.view addSubview:loadingView];
    [self.view bringSubviewToFront:_indicator];
    
    for(int i=0; i<[favoritePlaces count]; i++) {
        double latitude = [[[favoritePlaces objectAtIndex:i] objectForKey:@"placeLatitude"] doubleValue];
        double longitude = [[[favoritePlaces objectAtIndex:i] objectForKey:@"placeLongitude"]doubleValue];
        [self startAPICommunication:@"weather" :latitude :longitude :i];
    }
    
    if(communicationDisableFlag) {
        [self alertNetworkError];
    } else if (communicateAPIDisableFlag) {
        [self alertAPIError];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [weatherData removeAllObjects];
    [forecastData removeAllObjects];
    [favoritePlaces removeAllObjects];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// 遷移直前の処理
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DetailViewController *viewController = segue.destinationViewController;
    viewController.placeName = selectedPlaceName;
    viewController.detailLatitude = selectedPlaceLatitude;
    viewController.detailLongitude = selectedPlaceLongitude;
}

#pragma mark - TableView

// 表示行数の設定
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [favoritePlaces count];
}

// 表示するセルの生成
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"WeatherSummaryCell";
    
    WeatherSummaryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if([weatherData count] > 0 && [favoritePlaces count] == [weatherData count]) {
        // 天気情報
        NSDictionary *weatherDatum = [NSDictionary dictionaryWithDictionary:[weatherData objectAtIndex:indexPath.row]];
        
        cell.todayWeatherIconImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [[[weatherDatum objectForKey:@"weather"] objectAtIndex:0] objectForKey:@"icon" ]]];
        cell.temperatureLabel.text = [NSString stringWithFormat:@"%2.1f℃", [[[weatherDatum objectForKey:@"main"] objectForKey:@"temp"] doubleValue]];
        [cell.cellExpansionButton addTarget:self action:@selector(pushCellExpansionButton:event:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if([forecastData count] > 0) {
        // 3時間ごとの天気予報
        //cell.scrollView.hidden = NO;
        int fromTime = 0.0f;
        int toTime = 0.0f;
        cell.scrollView.contentSize = CGSizeMake(100.0*pageCount, 95.0);
        for(int i=0; i<pageCount; i++) {
            ThreeHourForecastView *forecastView = [[ThreeHourForecastView alloc] init];
            forecastView.frame = CGRectMake(100.0*i, 10.0, 100.0, 95.0);
            NSDictionary *forecast = [NSDictionary dictionaryWithDictionary:[forecastData objectAtIndex:i]];
            fromTime = [[forecast objectForKey:@"dt"] intValue];
            fromTime = ((fromTime / (60*60)) % 24) + 9;
            if(fromTime >=24) {
                fromTime = fromTime -24;
            }
            toTime = fromTime + 3;
            if(toTime >=24) {
                toTime = toTime -24;
            }
            forecastView.timeLabel.text = [NSString stringWithFormat:@"%d時〜%d時", fromTime, toTime];
            forecastView.precipitationLabel.text = [NSString stringWithFormat:@"%2.1f ml", [[[forecast objectForKey:@"rain"] objectForKey:@"3h"] doubleValue]];
            forecastView.icon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [[[forecast objectForKey:@"weather"] objectAtIndex:0] objectForKey:@"icon" ]]];
            [cell.scrollView addSubview:forecastView];
            forecastView = nil;
        }
        
    }
    
    cell.placeNameLabel.text = [[favoritePlaces objectAtIndex:indexPath.row] objectForKey:@"placeName"];
    
    //cell.scrollView.hidden = YES;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WeatherSummaryCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    float height = self.tableView.estimatedRowHeight -128;

    if(!cell.scrollView.hidden) {
        height = height + 128;
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

// セル選択
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *selectedPlace = [NSDictionary dictionaryWithDictionary:[favoritePlaces objectAtIndex:indexPath.row]];
    selectedPlaceName = [selectedPlace objectForKey:@"placeName"];
    selectedPlaceLongitude = [[selectedPlace objectForKey:@"placeLongitude"] doubleValue];
    selectedPlaceLatitude = [[selectedPlace objectForKey:@"placeLatitude"] doubleValue];
    [favoritePlaces removeAllObjects];
    [self.navigationController.visibleViewController performSegueWithIdentifier:@"goDetail" sender:self];
}

// セル削除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *indexPaths = [NSArray arrayWithObjects:indexPath, nil];
    [favoritePlaces removeObjectAtIndex:indexPath.row];
    
    [self deleteFavoritePlace:indexPath];
    
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    
    if([favoritePlaces count] == 0) {
        [self.view bringSubviewToFront:_addPlaceButton];
    } else {
        [self.view sendSubviewToBack:_addPlaceButton];
    }
}

// セルの並び替え
-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    // 移動項目の保持
    id item = [favoritePlaces objectAtIndex:sourceIndexPath.row];
    // 元あった場所から項目の削除
    [favoritePlaces removeObject:item];
    // 新しい位置に挿入
    [favoritePlaces insertObject:item atIndex:destinationIndexPath.row];
    // CoreData更新
    [self updateFavoritePlaceOrder];
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
    cell.cellExpansionButton.selected = !cell.cellExpansionButton.selected;
    
    if(cell.scrollView.hidden) {
        for (UIView *subview in cell.scrollView.subviews) {
            [subview removeFromSuperview];
        }
        [self.tableView reloadData];
    } else {
            double latitude = [[[favoritePlaces objectAtIndex:indexPath.row] objectForKey:@"placeLatitude"] doubleValue];
            double longitude = [[[favoritePlaces objectAtIndex:indexPath.row] objectForKey:@"placeLongitude"]doubleValue];
        [self.indicator startAnimating];
        [self.view addSubview:loadingView];
        [self.view bringSubviewToFront:_indicator];
        [self startAPICommunication:@"forecast" :latitude :longitude :0];
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
- (void)startAPICommunication:(NSString *)resource :(double)latitude :(double)longitude :(int)indexNumber{
    
    // URLの設定
    NSString *urlString = @"http://kominer:enimokR0150@api.openweathermap.org/data/2.5/";
    NSString *apiKey = @"165932781f9394ab99e2dfc1ab4e38cc";
    NSString *param = [NSString stringWithFormat:@"lat=%3.6lf&lon=%3.6lf&units=metric&appid=%@", latitude, longitude, apiKey];
    NSString *test = [NSString stringWithFormat:@"%@%@?%@", urlString, resource, param];
    NSURL *url = [NSURL URLWithString:[test stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]; 
    
    // Requestの設定
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    // Session, SessionConfigの生成
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    // DataTaskの生成
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
    
        // エラー処理
        if(error) {
            NSLog(@"Session Error:%@", error);
             communicationDisableFlag = YES;
            return;
        } else {
            communicationDisableFlag = NO;
        }
        
        // JSONのパース
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        
        if([jsonData objectForKey:@"cod"] == [NSNumber numberWithInteger:401]) {
            communicateAPIDisableFlag = YES;
        } else {
            communicateAPIDisableFlag = NO;
            if ([resource isEqualToString:@"weather"]) {
                // 天気情報を配列に追加
                [weatherData replaceObjectAtIndex:indexNumber withObject:jsonData];
            } else if([resource isEqualToString:@"forecast"]) {
                // 3時間ごとの天気予報を取得
                for(int i=0; i<pageCount; i++) {
                    [forecastData addObject:[[jsonData objectForKey:@"list"] objectAtIndex:i]];
                }
            }
        }
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.indicator stopAnimating];
            [loadingView removeFromSuperview];
            [self.tableView reloadData];
        });
    }];
 
    // タスクの実行
    [dataTask resume];
}

- (IBAction)addFavoritePlaceButton:(id)sender {
    self.tabBarController.selectedIndex = 1;
}

#pragma mark - CoreData

- (void)getFavoritePlace{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    
    // 一度に読み込むサイズを指定します。
    [fetchRequest setFetchLimit:20];
    
    // 検索結果をplaceOrderの昇順にする。
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"placeOrder" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // NSFetchedResultsController(結果を持ってくるクラス)の生成
    NSFetchedResultsController *fetchedResultsController
    = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                          managedObjectContext:self.context
                                            sectionNameKeyPath:nil
                                                     cacheName:nil];
    
    // データ検索
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
    }
    
    // データ取得、配列に追加
    NSArray *results = [NSArray arrayWithArray:[fetchedResultsController fetchedObjects]];
    for (FavoritePlaces *data in results) {
        NSString *name = data.placeName;
        NSDictionary *place = [NSDictionary dictionaryWithObjectsAndKeys:name, @"placeName", data.placeLatitude, @"placeLatitude", data.placeLongitude, @"placeLongitude", nil];
        [favoritePlaces addObject:place];
        place = nil;
    }
}

- (void)deleteFavoritePlace:(NSIndexPath *)indexPath {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"placeOrder" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSArray *results = [self.context executeFetchRequest:fetchRequest error:nil];
    
    FavoritePlaces *place = [results objectAtIndex:indexPath.row];
    [self.context deleteObject:place];
    
    NSError *error = nil;
    if(![self.context save:&error]) {
        NSLog(@"Error:%@", error);
    }
}

- (void)updateFavoritePlaceOrder{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"placeOrder" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSArray *results = [self.context executeFetchRequest:fetchRequest error:nil];

    for (int i=0; i<[results count]; i++) {
        FavoritePlaces *data = [results objectAtIndex:i];
        NSDictionary *placeData = [NSDictionary dictionaryWithDictionary:[favoritePlaces objectAtIndex:i]];
        data.placeName = [placeData objectForKey:@"placeName"];
        data.placeLatitude = [placeData objectForKey:@"placeLatitude"];
        data.placeLongitude = [placeData objectForKey:@"placeLongitude"];
        data.placeOrder = [NSNumber numberWithInt:i];
    }
    
    NSError *error = nil;
    if(![self.context save:&error]) {
        NSLog(@"Error:%@", error);
    }
}

#pragma mark - Alert

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

@end
