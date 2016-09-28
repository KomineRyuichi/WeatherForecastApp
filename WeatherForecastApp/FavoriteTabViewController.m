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
#import "APICommunication.h"
#import "CurrentWeatherData.h"
#import <QuartzCore/QuartzCore.h>

@interface WeatherSummaryCell : UITableViewCell {
    UIView *cellLoadingView;
}
@property (weak, nonatomic) IBOutlet UIImageView *todayWeatherIconImage;
@property (weak, nonatomic) IBOutlet UILabel *placeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UIButton *cellExpansionButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *cellIndicator;

- (void)startLoad;
- (void)stopLoad;
@end

@implementation WeatherSummaryCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // ロード時の暗転処理用のview
    cellLoadingView = [[UIView alloc] initWithFrame:CGRectMake(self.scrollView.center.x-25, self.scrollView.center.y-25, 50, 50)];
    cellLoadingView.backgroundColor = [UIColor blackColor];
    cellLoadingView.alpha = 0.5f;
    cellLoadingView.layer.cornerRadius = 5;
    cellLoadingView.clipsToBounds = YES;

    self.temperatureLabel.text = @"　℃";
    [self.cellExpansionButton setImage:[UIImage imageNamed:@"open"] forState:UIControlStateNormal];
    [self.cellExpansionButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateSelected];
}

- (void)startLoad {
    [self.cellIndicator startAnimating];
    [self addSubview:cellLoadingView];
    [self bringSubviewToFront:_cellIndicator];
}

- (void)stopLoad {
    [self.cellIndicator stopAnimating];
    [cellLoadingView removeFromSuperview];
}

@end

@interface FavoriteTabViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *weatherData;
    NSMutableArray *forecastData;
    NSMutableArray *cellHeightData;
    NSArray *forecastViewArray;
    NSMutableArray *favoritePlaces;
    NSIndexPath *selectedCellIndexPath;
    NSString *selectedPlaceName;
    double selectedPlaceLatitude;
    double selectedPlaceLongitude;
    float cellHeight;
    UIAlertController *networkAlertController;
    UIAlertController *apiAlertController;
    NSInteger pageCount;
    UIView *loadingView;
    APICommunication *apiCommunication;
    CurrentWeatherData *currentWeatherData;
    BOOL cellExpansinOpenFlag;
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
    
    // 3時間ごとの天気予報を表示するviewの数
    //その時刻から24時間分取得したいので24/3=8で8となっている
    pageCount = 8;
    
    //タブバータイトル、アイコンの設定
    self.navigationController.visibleViewController.tabBarItem.image = [UIImage imageNamed:@"FavoriteTab"];
    self.navigationController.visibleViewController.tabBarItem.title = @"Favorite";
    
    // テーブルのデリゲート、データソースの設定
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    // セルの高さ設定
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 200.0f;
    cellHeight = self.tableView.estimatedRowHeight;
    
    // 配列の初期化
    weatherData = [NSMutableArray array];
    forecastData = [NSMutableArray array];
    favoritePlaces = [NSMutableArray array];
    cellHeightData = [NSMutableArray array];
    
    // contextの設定
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication.sharedApplication delegate];
    self.context = [appDelegate managedObjectContext];
    
    //アラートの設定
    networkAlertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"オフラインです。" preferredStyle:UIAlertControllerStyleAlert];
    apiAlertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"API規制です。" preferredStyle:UIAlertControllerStyleAlert];
    
    //アラート時のアクションの設定
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
    
    // アラートにアクションを追加
    [networkAlertController addAction:action];
    [apiAlertController addAction:action];
    
    // ロード時の暗転処理用のview
    loadingView = [[UIView alloc] initWithFrame:CGRectMake(self.view.center.x-50, self.view.center.y-50, 100, 100)];
    loadingView.backgroundColor = [UIColor blackColor];
    loadingView.alpha = 0.5f;
    loadingView.layer.cornerRadius = 5;
    loadingView.clipsToBounds = YES;
    
    apiCommunication = [[APICommunication alloc] init];
    currentWeatherData = [CurrentWeatherData getInstance];
    
    selectedCellIndexPath = nil;
}

// 画面表示直前に呼ばれるメソッド
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // ナビゲーションのタイトル、アイテムの設定
    self.navigationController.visibleViewController.navigationItem.title = @"お気に入り";
    self.navigationController.visibleViewController.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = NO;
    
    // 開閉フラグの初期化
    cellExpansinOpenFlag = NO;
    
    // レコードの取得
    [self getFavoritePlace];
    
    // レコードの件数分天気情報配列の要素を確保
    for (int i = 0; i < [favoritePlaces count]; i++)
    {
        [weatherData addObject:[NSDictionary dictionary]];
        [cellHeightData addObject:[NSNumber numberWithFloat:cellHeight]];
    }

    // レコードの有無によって、「お気に入りを追加」のボタンを表示するか否かを判別
    if([favoritePlaces count]  == 0) {
        [self.view bringSubviewToFront:_addPlaceButton];
    } else {
        [self.view sendSubviewToBack:_addPlaceButton];
    }
    
    if([favoritePlaces count] > 0) {
        // インジケーターくるくるスタート
        [self.indicator startAnimating];
        [self.view addSubview:loadingView];
        [self.view bringSubviewToFront:_indicator];
    }
}

// 画面表示直後の処理
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // API通信開始
    for(int i=0; i<[favoritePlaces count]; i++) {
        double latitude = [[[favoritePlaces objectAtIndex:i] objectForKey:@"placeLatitude"] doubleValue];
        double longitude = [[[favoritePlaces objectAtIndex:i] objectForKey:@"placeLongitude"]doubleValue];
    
        [apiCommunication startAPICommunication:@"weather" :latitude :longitude :^(NSDictionary *result, BOOL networkOfflineFlag, BOOL apiRegulationFlag){
    
            if((networkOfflineFlag || apiRegulationFlag) && i == 0) {
                [self stopIndicator];
                if(networkOfflineFlag) {
                    [self alertNetworkError];
                } else if (apiRegulationFlag) {
                    [self alertAPIError];
                }
            } else if ((networkOfflineFlag || apiRegulationFlag) && i > 0) {
                return;
            } else {
                [weatherData replaceObjectAtIndex:i withObject:result];
                [self.tableView reloadData];
                if(i == [favoritePlaces count] -1) {
                    [self stopIndicator];
                }
            }
        }];
    }

}

// 画面が消えた直後に呼ばれるメソッド
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // 各配列の要素を削除
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
    
    if([forecastData count] > 0 && indexPath.row == selectedCellIndexPath.row) {
        cell.scrollView.hidden = NO;
        cell.cellExpansionButton.selected = YES;
        // 3時間ごとの天気予報
        int fromTime = 0.0f;
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
            forecastView.timeLabel.text = [NSString stringWithFormat:@"%d時", fromTime];
            forecastView.precipitationLabel.text = [NSString stringWithFormat:@"%2.1f ml", [[[forecast objectForKey:@"rain"] objectForKey:@"3h"] doubleValue]];
            forecastView.icon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [[[forecast objectForKey:@"weather"] objectAtIndex:0] objectForKey:@"icon" ]]];
            [cell.scrollView addSubview:forecastView];
            forecastView = nil;
        }
    } else {
        cell.cellExpansionButton.selected = NO;
        cell.scrollView.hidden = YES;
    }
    
    cell.placeNameLabel.text = [[favoritePlaces objectAtIndex:indexPath.row] objectForKey:@"placeName"];

    return cell;
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
    [cellHeightData removeAllObjects];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    float height = [[cellHeightData objectAtIndex:indexPath.row] floatValue];
    
    [cellHeightData replaceObjectAtIndex:indexPath.row withObject:@(height)];
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //float height = 200.0f;

    float height = [[cellHeightData objectAtIndex:indexPath.row] floatValue];
    
    if (cellExpansinOpenFlag && indexPath.row == selectedCellIndexPath.row) {
        height = 200.0f;
    } else {
        height = 73.0f;
    }
    [cellHeightData replaceObjectAtIndex:indexPath.row withObject:@(height)];
    return height;
}

#pragma mark - Other

// 拡張ボタンアクション
- (void)pushCellExpansionButton:(UIButton *)sender event:(UIEvent *)event {
    selectedCellIndexPath = [self indexPathForControlEvent:event];
    WeatherSummaryCell *cell = [self.tableView cellForRowAtIndexPath:selectedCellIndexPath];
    
    cell.cellExpansionButton.selected = !cell.cellExpansionButton.selected;
    cellExpansinOpenFlag = cell.cellExpansionButton.selected;
    
    if(cell.cellExpansionButton.selected) {
        [forecastData removeAllObjects];
        double latitude = [[[favoritePlaces objectAtIndex:selectedCellIndexPath.row] objectForKey:@"placeLatitude"] doubleValue];
        double longitude = [[[favoritePlaces objectAtIndex:selectedCellIndexPath.row] objectForKey:@"placeLongitude"]doubleValue];
        //[cell startLoad];
        // インジケーターくるくるスタート
        [self.indicator startAnimating];
        [self.view addSubview:loadingView];
        [self.view bringSubviewToFront:_indicator];
        for (UIView *subview in cell.scrollView.subviews) {
            [subview removeFromSuperview];
        }
        [apiCommunication startAPICommunication:@"forecast" :latitude :longitude :^(NSDictionary *result, BOOL networkOfflineFlag, BOOL apiRegulationFlag){
        
            if(networkOfflineFlag || apiRegulationFlag) {
                [cell stopLoad];
                if(networkOfflineFlag) {
                    [self alertNetworkError];
                } else if (apiRegulationFlag) {
                    [self alertAPIError];
                }
            } else {
                for(int i=0; i<pageCount; i++)  {
                    [forecastData addObject:[[result objectForKey:@"list"] objectAtIndex:i]];
                }
                [self.tableView reloadData];
               // [cell stopLoad];
                [self stopIndicator];
            }
        }];
    } else {
        [forecastData removeAllObjects];
        for (UIView *subview in cell.scrollView.subviews) {
            [subview removeFromSuperview];
        }
        [self.tableView reloadData];
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


// 「お気に入りを追加」のボタンタップ時のアクション
- (IBAction)addFavoritePlaceButton:(id)sender {
    // タブ切り替え 0:お気に入り画面、1:地図画面
    self.tabBarController.selectedIndex = 1;
}

// インジケータ止める
- (void)stopIndicator {
    [self.indicator stopAnimating];
    [loadingView removeFromSuperview];
}

#pragma mark - CoreData

// レコード検索
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
#if DEBUG
        NSLog(@"Error:%@", error);
#endif
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

// レコード削除
- (void)deleteFavoritePlace:(NSIndexPath *)indexPath {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    
    // レコードをplaceOrderの昇順に取得
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"placeOrder" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // レコード取得実行
    NSArray *results = [self.context executeFetchRequest:fetchRequest error:nil];
    
    // 該当するレコードの取得
    FavoritePlaces *place = [results objectAtIndex:indexPath.row];
    
    // レコード削除
    [self.context deleteObject:place];
    
    // 操作を保存
    NSError *error = nil;
    if(![self.context save:&error]) {
#if DEBUG
        NSLog(@"Error:%@", error);
#endif
    }
}

// レコードの更新
- (void)updateFavoritePlaceOrder{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    
    // レコードをplaceOrderの昇順に取得
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"placeOrder" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // レコード取得実行
    NSArray *results = [self.context executeFetchRequest:fetchRequest error:nil];

    // 全レコードに対して、placeOrderを更新
    for (int i=0; i<[results count]; i++) {
        FavoritePlaces *data = [results objectAtIndex:i];
        NSDictionary *placeData = [NSDictionary dictionaryWithDictionary:[favoritePlaces objectAtIndex:i]];
        data.placeName = [placeData objectForKey:@"placeName"];
        data.placeLatitude = [placeData objectForKey:@"placeLatitude"];
        data.placeLongitude = [placeData objectForKey:@"placeLongitude"];
        data.placeOrder = [NSNumber numberWithInt:i];
    }
    
    // 操作を保存
    NSError *error = nil;
    if(![self.context save:&error]) {
#if DEBUG
        NSLog(@"Error:%@", error);
#endif
    }
}

#pragma mark - Alert

// オフライン時のアラート
- (void)alertNetworkError {
    UIViewController *baseView = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (baseView.presentedViewController != nil && !baseView.presentedViewController.isBeingDismissed) {
        baseView = baseView.presentedViewController;
    }
    [baseView presentViewController:networkAlertController animated:YES completion:nil];
}

// API規制時のアラート
- (void)alertAPIError {
    UIViewController *baseView = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (baseView.presentedViewController != nil && !baseView.presentedViewController.isBeingDismissed) {
        baseView = baseView.presentedViewController;
    }
    [baseView presentViewController:apiAlertController animated:YES completion:nil];
}

@end
