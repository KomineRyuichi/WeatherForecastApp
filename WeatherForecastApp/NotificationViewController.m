//
//  NotificationViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/16.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "NotificationViewController.h"
#import "onOffTableViewCell.h"
#import "placeNameTableViewCell.h"
#import "timeTableViewCell.h"
#import "DatePickerViewController.h"
#import "PlaceNameViewController.h"


@interface NotificationViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    UILocalNotification *notificationObject;
    BOOL screenTransitionFlag;
    NSString *placeName;
    NSNumber *placeLatitude;
    NSNumber *placeLongitude;
    NSDate *notificationDate;
    
    UITableViewCell *cell;
    onOffTableViewCell *onOffCell;
    placeNameTableViewCell *placeNameCell;
    timeTableViewCell *timeCell;

}
@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _NotificationTableView.delegate = self;
    _NotificationTableView.dataSource = self;
    //カスタムセルを指定
    //UINib *nib1 = [UINib nibWithNibName:@"onOffTableViewCell" bundle:nil];
    //UINib *nib2 = [UINib nibWithNibName:@"placeAndTimeTableViewCell" bundle:nil];
    //[self.NotificationTableView registerNib:nib1 forCellReuseIdentifier:@"notificationTableCell"];
    //[self.NotificationTableView registerNib:nib2 forCellReuseIdentifier:@"notificationTableCell"];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;

}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //static const id identifiers[3] = {@"onOffTableViewCell",@"placeAndTimeTableViewCell",@"placeAndTimeTableViewCell"};
    //NSString *CellIdentifier = identifiers[indexPath.row];
    //cell = [self.NotificationTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //if (cell == nil) {
        switch (indexPath.row) {
            case 0:
                onOffCell = [[onOffTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"onOffTableViewCell"];
                [onOffCell.onOffSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                cell = onOffCell;
                break;
            case 1:
                placeNameCell = [[placeNameTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"placeAndTimeTableViewCell"];
                placeNameCell.titleLabel.text = @"通知する地点";
                //暫定
                placeNameCell.placeNameLabel.text = @"未設定";
                cell = placeNameCell;
                break;
            case 2:
                placeTimeCell = [[placeAndTimeTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"placeAndTimeTableViewCell"];
                placeTimeCell.titleLabel.text = @"通知する時間";
                //暫定
                placeTimeCell.placeNameLabel.text = @"未設定";
                cell = placeTimeCell;
                break;
        }
    //}
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
            break;
        case 1:
            screenTransitionFlag = YES;
            [self performSegueWithIdentifier:@"toPlaceNameView" sender:self];
            break;
        case 2:
            screenTransitionFlag = NO;
            [self performSegueWithIdentifier:@"toDatePickerView" sender:self];
            break;
    }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if(screenTransitionFlag){
        PlaceNameViewController *placeNameViewController = segue.destinationViewController;
        //__weak typeof(self) weakSelf = self;
        placeNameViewController.dataBlocks = ^(NSString *text,NSNumber *latitude,NSNumber *longitude){
            placeName = text;
            placeLatitude = latitude;
            placeLongitude = longitude;
            
            placeTimeCell.placeNameLabel.text = placeName;
        };
    }else{
        DatePickerViewController *datePickerViewController = segue.destinationViewController;
        datePickerViewController.pickerBlocks = ^(NSString *text){
            //test
            notificationDate = [NSDate date];
        };
    }
}

#pragma mark - ON/PFF Switch
- (void)switchChanged:(UISwitch*)switchParts
{
    if( switchParts.on )
    {
        [self registerNotification];
        NSLog(@"テスト：ON");
    }
    else
    {
        // offの時の処理
        // 通知の取り消し
        NSLog(@"テスト：OFF");
    }
}


#pragma mark - Local Notification
//①通知タイプの登録
-(void)registerNotification{
    // 許可をもらう通知タイプの種類を定義
    UIUserNotificationType types = UIUserNotificationTypeBadge | // アイコンバッチ
    UIUserNotificationTypeSound | // サウンド
    UIUserNotificationTypeAlert;  // テキスト
    // UIUserNotificationSettingsの生成
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    // アプリケーションに登録
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    NSLog(@"①通知タイプ登録完了");
    [self createNotificationObject];
}
//②通知オブジェクトの生成と内容指定
-(void)createNotificationObject{
    // インスタンス生成
    notificationObject = [[UILocalNotification alloc] init];
    // 通知時間（15秒後）
    notificationObject.fireDate = [NSDate dateWithTimeIntervalSinceNow:(15)];
    // タイムゾーン
    notificationObject.timeZone = [NSTimeZone defaultTimeZone];
    // メッセージ
    notificationObject.alertBody = @"15秒経過しました。";
    // 音
    notificationObject.soundName = UILocalNotificationDefaultSoundName;
    // 通知の登録
    [[UIApplication sharedApplication] scheduleLocalNotification:notificationObject];
    NSLog(@"②通知オブジェクト生成・内容指定完了");
    [self createSchedule];
}
//③スケジューリング
-(void)createSchedule{
    [[UIApplication sharedApplication] scheduleLocalNotification:notificationObject];
    NSLog(@"③スケジューリング完了");
}
//通知を受信した時の処理はAppDelegate.mのdidReceiveLocalNotificationに記述


#pragma mark - Other
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
