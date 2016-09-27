//
//  OtherTabViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-089 on 2016/09/16.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "OtherTabViewController.h"

@interface OtherTabViewController () <UITableViewDataSource, UITableViewDelegate>{
    NSArray *cells;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OtherTabViewController

// 読み込まれた直後に行う処理
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.estimatedRowHeight = 73.0f;
    
    cells = [NSArray arrayWithObjects:@"閲覧履歴", @"通知設定",  nil];
}

// 画面表示する直前に行う処理
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.visibleViewController.navigationItem.title = @"その他";
     self.navigationController.visibleViewController.tabBarController.tabBar.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView

// セルの個数を決める処理
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [cells count];
}

// セルを生成する処理
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = [cells objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont fontWithName:@"Arial" size:24];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

// セルを選択したときの処理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *segueID = [[NSString alloc] init];
    
    if(indexPath.row == 0) {
        segueID = @"goHistory";
    } else {
        segueID = @"goNotification";
    }
    
    [self performSegueWithIdentifier:segueID sender:self];
}
@end
