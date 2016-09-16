//
//  HistoryViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/16.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "HistoryViewController.h"
#import "DetailViewController.h"
#import "FavoritePlaces.h"
#import "History.h"
#import "AppDelegate.h"



@interface HistoryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *placeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;


@end

@implementation HistoryCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // OFFの画像設定
    [self.favoriteButton setImage:[UIImage imageNamed:@"NonFavorite"] forState:UIControlStateNormal];
    // ONの画像設定
    [self.favoriteButton setImage:[UIImage imageNamed:@"AddFavorite"] forState:UIControlStateSelected];
}

@end

@interface HistoryViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSDateFormatter *dateFormatter;
    NSMutableArray *historyData;
    NSString *selectedPlaceName;
    double selectedPlaceLatitude;
    double selectedPlaceLongitude;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSManagedObjectContext *context;
@end

@implementation HistoryViewController

#pragma mark - ViewController

// 読み込まれた直後の処理
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.estimatedRowHeight = 55.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    // contectの設定
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication.sharedApplication delegate];
    self.context = [appDelegate managedObjectContext];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy/MM/dd";
}

// 画面が表示される直前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.visibleViewController.title = @"閲覧履歴";
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = YES;
    
    historyData = [NSMutableArray array];
    
    [self searchForViewHistory];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// 画面遷移する直前
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DetailViewController *viewController = segue.destinationViewController;
    viewController.placeName = selectedPlaceName;
    viewController.detailLatitude = selectedPlaceLatitude;
    viewController.detailLongitude = selectedPlaceLongitude;
}

#pragma mark - TableView

// セルの個数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [historyData count];
}

// セル生成時の処理
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HistoryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"HistoryCell"];
    NSDictionary *history = [historyData objectAtIndex:indexPath.row];
    
    cell.placeNameLabel.text = [history objectForKey:@"placeName"];
    cell.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:[history objectForKey:@"date"]]];
    [cell.favoriteButton addTarget:self action:@selector(addFavorite:event:) forControlEvents:UIControlEventTouchUpInside];
    
    if([self searchFavoritePlace:[history objectForKey:@"placeName"]]) {
        cell.favoriteButton.selected = YES;
    } else {
        cell.favoriteButton.selected = NO;
    }
    
    return cell;
}

// セルの高さ計算
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _tableView.estimatedRowHeight;
}

// セル選択時の処理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *selectedPlace = [historyData objectAtIndex:indexPath.row];
    selectedPlaceName = [selectedPlace objectForKey:@"placeName"];
    selectedPlaceLatitude = [[selectedPlace objectForKey:@"placeLatitude"] floatValue];
    selectedPlaceLongitude = [[selectedPlace objectForKey:@"placeLongitude"] floatValue];
    
    [self performSegueWithIdentifier:@"goDetail" sender:self];
}

#pragma mark - Other

// お気に入り追加アクション
- (void)addFavorite:(UIButton *)sender event:(UIEvent *)event{
    NSIndexPath *indexPath = [self indexPathForControlEvent:event];
    NSDictionary *place = [historyData objectAtIndex:indexPath.row];
    NSString *placeName = [place objectForKey:@"placeName"];
    double placeLatitude = [[place objectForKey:@"placeLatitude"] doubleValue];
    double placeLongitude = [[place objectForKey:@"placeLongitude"] doubleValue];
    
    sender.selected = !sender.selected;
    
    if(sender.selected) {
        [self registerFavoritePlaceToCoreData:placeName Latitude:placeLatitude Longitude:placeLongitude];
    } else {
        [self deleteFavoritePlace:placeName];
    }
    
}

// 押されたボタンの行番号を返す
- (NSIndexPath *)indexPathForControlEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    return indexPath;
}

#pragma mark - CoreData

// お気に入り登録
- (void)registerFavoritePlaceToCoreData:(NSString *)placeName Latitude:(double)placeLatitude Longitude:(double)placeLongitude{
    FavoritePlaces *newPlace = [NSEntityDescription insertNewObjectForEntityForName:@"FavoritePlaces" inManagedObjectContext:self.context];
    
    newPlace.placeName = placeName;
    newPlace.placeLatitude = [NSNumber numberWithDouble:placeLatitude];
    newPlace.placeLongitude = [NSNumber numberWithDouble:placeLongitude];
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

// お気に入り削除
- (void)deleteFavoritePlace:(NSString *)placeName {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"placeName=%@", placeName];
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

// 既にお気に入りされているかどうかの確認(されていればYES, そうでなければNO)
- (BOOL)searchFavoritePlace:(NSString *)placeName {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"FavoritePlaces"];
    
    // 一度に読み込むサイズを指定します。
    [fetchRequest setFetchLimit:20];
    
    // 検索結果をplaceOrderの昇順にする。
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"placeOrder" ascending:YES];
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
        return YES;
    } else {
        return NO;
    }
}

// 履歴検索
- (void)searchForViewHistory{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"History"];
    
    // 一度に読み込むサイズを指定します。
    [fetchRequest setFetchLimit:20];
    
    // 検索結果をplaceOrderの昇順にする。
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
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
    for (History *data in results) {
        NSString *name = data.placeName;
        NSDictionary *place = [NSDictionary dictionaryWithObjectsAndKeys:name, @"placeName", data.placeLatitude, @"placeLatitude", data.placeLongitude, @"placeLongitude", data.date, @"date", nil];
        [historyData addObject:place];
        place = nil;
    }
}


@end
