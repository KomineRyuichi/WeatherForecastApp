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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.estimatedRowHeight = 73.0f;
    
    cells = [NSArray arrayWithObjects:@"閲覧履歴", @"通知設定",  nil];
}

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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [cells count];
}

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *segueID = [[NSString alloc] init];
    
    if(indexPath.row == 0) {
        segueID = @"goHistory";
    } else {
        segueID = @"";
    }
    
    [self performSegueWithIdentifier:segueID sender:self];
}
@end
