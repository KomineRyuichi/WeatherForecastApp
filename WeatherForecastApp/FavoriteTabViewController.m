//
//  FavoriteTabViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/01.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "FavoriteTabViewController.h"

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
    
    self.scrollView.hidden = YES;
}

@end

@interface ForecastView : UIView

@end

@implementation ForecastView

@end

@interface FavoriteTabViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *label;


@end

@implementation FavoriteTabViewController

#pragma marl - ViewController

// 読み込み直後の処理
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"お気に入り";
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    // セルの高さ設定
    self.tableView.estimatedRowHeight = 200.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

}

// 画面表示直後の処理
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    return 3;
}

// 表示するセルの生成
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"WeatherSummaryCell";
    
    WeatherSummaryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    [cell.cellExpansionButton addTarget:self action:@selector(pushCellExpansionButton:event:) forControlEvents:UIControlEventTouchUpInside];
    
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //[self.navigationController performSegueWithIdentifier:@"goDetail" sender:self];
}
#pragma mark - Other

// 拡張ボタンアクション
- (void)pushCellExpansionButton:(UIButton *)sender event:(UIEvent *)event {
    NSIndexPath *indexPath = [self indexPathForControlEvent:event];
    WeatherSummaryCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    cell.scrollView.hidden = !cell.scrollView.hidden;
    
    [self.tableView reloadData];

}

// 押されたボタンの行番号を返す
- (NSIndexPath *)indexPathForControlEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    return indexPath;
}

@end
