//
//  PlaceNameViewController.m
//  WeatherForecastApp
//
//  Created by 岩上遥平 on 2016/09/26.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "PlaceNameViewController.h"
#import "AppDelegate.h"
#import "FavoritePlaces.h"

@interface PlaceNameViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    UITableViewCell *cell;
    NSMutableArray *favoritePlaces;
    NSDictionary *dic;
}
@property (strong, nonatomic) NSManagedObjectContext *context;
@end

@implementation PlaceNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _placeNameTableView.dataSource = self;
    _placeNameTableView.delegate = self;
    favoritePlaces = [NSMutableArray array];
    // contectの設定
    AppDelegate *appDelegate = [UIApplication.sharedApplication delegate];
    self.context = [appDelegate managedObjectContext];
    [self getFavoritePlace];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [favoritePlaces count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    cell = [self.placeNameTableView dequeueReusableCellWithIdentifier:@"placeNameCell"];
    dic = [favoritePlaces objectAtIndex:indexPath.row];
    cell.textLabel.text = [dic objectForKey:@"placeName"];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    cell = [self.placeNameTableView cellForRowAtIndexPath:indexPath];
    dic = [favoritePlaces objectAtIndex:indexPath.row];
    _dataBlocks([dic objectForKey:@"placeName"],[dic objectForKey:@"placeLatitude"],[dic objectForKey:@"placeLongitude"]);
    [self.navigationController popViewControllerAnimated:YES];
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


#pragma mark - Other
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
