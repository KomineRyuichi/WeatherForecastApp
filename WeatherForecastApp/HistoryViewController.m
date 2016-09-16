//
//  HistoryViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/16.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "HistoryViewController.h"

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
    NSDateFormatter *dataFormatter;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation HistoryViewController

#pragma mark - ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - TableView

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    HistoryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@""];
//}


@end
