//
//  DatePickerViewController.h
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/16.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DatePickerViewControllerDelegate;

@interface DatePickerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) id<DatePickerViewControllerDelegate> delegate;

@property (nonatomic, assign) int datePickerMode;
@property (nonatomic, retain) NSString *pickerName;
@property (nonatomic, retain) NSDate *minDate;
@property (nonatomic, retain) NSDate *maxDate;
@property (nonatomic, retain) NSDate *iniDate; // 初期値

@property (nonatomic)void(^pickerBlocks)(NSDate *);

@end

@protocol DatePickerViewControllerDelegate <NSObject>
// 選択された文字列を適用するためのデリゲートメソッド
//-(void)applySelectedString:(NSString *)str;
-(void)applySelectedString:(NSDate *)str;
// 当該PickerViewを閉じるためのデリゲートメソッド
-(void)closePickerView:(DatePickerViewController *)controller;
@end
