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
    UINib *nib1 = [UINib nibWithNibName:@"onOffTableViewCell" bundle:nil];
    [self.NotificationTableView registerNib:nib1 forCellReuseIdentifier:@"notificationTableCell1"];
    UINib *nib2 = [UINib nibWithNibName:@"placeNameTableViewCell" bundle:nil];
    [self.NotificationTableView registerNib:nib2 forCellReuseIdentifier:@"notificationTableCell2"];
    UINib *nib3 = [UINib nibWithNibName:@"timeTableViewCell" bundle:nil];
    [self.NotificationTableView registerNib:nib3 forCellReuseIdentifier:@"notificationTableCell3"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;

}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
        switch (indexPath.row) {
            case 0:
                //onOffCell = [[onOffTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"onOffTableViewCell"];
                onOffCell = [_NotificationTableView dequeueReusableCellWithIdentifier:@"notificationTableCell1"];
                [onOffCell.onOffSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                return onOffCell;
                break;
            case 1:
                //placeNameCell = [[placeNameTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"placeNameTableViewCell"];
                placeNameCell = [_NotificationTableView dequeueReusableCellWithIdentifier:@"notificationTableCell2"];
                placeNameCell.titlelabel.text = @"通知する地点";
                //暫定
                placeNameCell.placeNameLabel.text = @"未設定";
                return placeNameCell;
                break;
            case 2:
                //timeCell = [[timeTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"timeTableViewCell"];
                timeCell = [_NotificationTableView dequeueReusableCellWithIdentifier:@"notificationTableCell3"];
                timeCell.titleLabel.text = @"通知する時間";
                //暫定
                timeCell.timeLabel.text = @"未設定";
                return timeCell;
                break;
            default:
               return cell;
        }
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
            
            placeNameCell.placeNameLabel.text = placeName;
            NSLog(@"%@",placeName);
        };
    }else{
        DatePickerViewController *datePickerViewController = segue.destinationViewController;
        datePickerViewController.pickerBlocks = ^(NSDate *date){
            //test
            //notificationDate = [NSDate date];
            notificationDate = date;
            timeCell.timeLabel.text = notificationDate;
            NSLog(@"%@",notificationDate);
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
