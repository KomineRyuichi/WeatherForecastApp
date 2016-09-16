//
//  DatePickerViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/16.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "DatePickerViewController.h"

@interface DatePickerViewController ()

@end

@implementation DatePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}





- (IBAction)closeButton:(UIButton *)sender {
    _pickerBlocks(@"");
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
