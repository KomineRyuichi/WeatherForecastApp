//
//  PlaceNameViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/16.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "PlaceNameViewController.h"

@interface PlaceNameViewController ()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation PlaceNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _PlaceNameTableView.dataSource = self;
    _PlaceNameTableView.delegate = self;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [_PlaceNameTableView dequeueReusableCellWithIdentifier:@"placeNameCell"];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
