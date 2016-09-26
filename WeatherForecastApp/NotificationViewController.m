//
//  NotificationViewController.m
//  WeatherForecastApp
//
//  Created by 岩上遥平 on 2016/09/25.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "NotificationViewController.h"
#import "SwitchTableViewCell.h"
#import "PlaceNameTableViewCell.h"
#import "TimeTableViewCell.h"
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
    SwitchTableViewCell *onOffCell;
    PlaceNameTableViewCell *placeNameCell;
    TimeTableViewCell *timeCell;
    
    //UserDefaultsにスイッチの状態を知らせるための変数
    BOOL notificationSwitch;
}
@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _notificationTableView.delegate = self;
    _notificationTableView.dataSource = self;
    //カスタムセルを指定
    UINib *nib1 = [UINib nibWithNibName:@"SwitchTableViewCell" bundle:nil];
    [self.notificationTableView registerNib:nib1 forCellReuseIdentifier:@"notificationTableCell1"];
    UINib *nib2 = [UINib nibWithNibName:@"PlaceNameTableViewCell" bundle:nil];
    [self.notificationTableView registerNib:nib2 forCellReuseIdentifier:@"notificationTableCell2"];
    UINib *nib3 = [UINib nibWithNibName:@"TimeTableViewCell" bundle:nil];
    [self.notificationTableView registerNib:nib3 forCellReuseIdentifier:@"notificationTableCell3"];
    
    //スイッチの初期値がONならswitchChanged:を呼んで、起動時にも通知が設定されるようにする
    //最終的にはお気に入り画面からswitchChanged:を呼ぶ？
//    NSLog(@"てすと：%d",[[self readData:@"switch"]boolValue]);
//    if([[self readData:@"switch"]boolValue]){
//        NSLog(@"switchChanged:呼び出し！");
//        [self switchChanged:[[self readData:@"switch"]boolValue]];
//    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:{
            //onOffCell = [[onOffTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"onOffTableViewCell"];
            onOffCell = [_notificationTableView dequeueReusableCellWithIdentifier:@"notificationTableCell1"];
            onOffCell.onOffSwitch.on = [[self readData:@"switch"] boolValue];
            [onOffCell.onOffSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            return onOffCell;
            break;
        }
        case 1:{
            //placeNameCell = [[placeNameTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"placeNameTableViewCell"];
            placeNameCell = [_notificationTableView dequeueReusableCellWithIdentifier:@"notificationTableCell2"];
            placeNameCell.titlelabel.text = @"通知する地点";
            //Userdefaultsにデータがあるかどうかを判断
            NSString *placeText = [self readData:@"place"];
            if(placeText==nil){
                placeText = @"未設定";
            }
            placeNameCell.placeNameLabel.text = placeText;
            return placeNameCell;
            break;
        }
        case 2:{
            //timeCell = [[timeTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"timeTableViewCell"];
            timeCell = [_notificationTableView dequeueReusableCellWithIdentifier:@"notificationTableCell3"];
            timeCell.titleLabel.text = @"通知する時間";
            //Userdefaultsにデータがあるかどうかを判断
            NSDate *time = [self readData:@"time"];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"HH:mm"];
            NSString *timeText = [formatter stringFromDate:time];
            if(timeText==nil){
                timeText = @"未設定";
            }
            timeCell.timeLabel.text = timeText;
            return timeCell;
            break;
        }
        default:{
            return cell;
        }
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
            placeNameCell.placeNameLabel.text = text;
            //通知用
            placeName = text;
            placeLatitude = latitude;
            placeLongitude = longitude;
            //UserDefaults
            [self saveData:@"place"];
        };
    }else{
        DatePickerViewController *datePickerViewController = segue.destinationViewController;
        datePickerViewController.pickerBlocks = ^(NSDate *date){
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"HH:mm"];
            NSString *dateStr = [formatter stringFromDate:date];
            timeCell.timeLabel.text = dateStr;
            //UserDefaultsでの保存に使用
            notificationDate = date;
            //UserDefaults
            [self saveData:@"time"];
        };
    }
}

#pragma mark - ON/OFF Switch
//地点、時間が未設定の時はアラート？
- (void)switchChanged:(UISwitch *)switchParts{
    if( switchParts.on ){
        // Onの時の処理
        notificationSwitch = switchParts.on;
        if ([self readData:@"place"] == nil || [self readData:@"time"] == nil){
            //地名・時間が設定されていなければアラート
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"条件を設定してください"] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        }else{
            //UserDefaults
            [self saveData:@"switch"];
            // 通知のリセット
            [[UIApplication sharedApplication] cancelLocalNotification:notificationObject];
            // 通知の登録開始
            [self registerNotification];
            NSLog(@"テスト：ON");
        }
    }else{
        // Offの時の処理
        notificationSwitch = switchParts.on;
        //UserDefaults
        [self saveData:@"switch"];
        // 通知のリセット
        [[UIApplication sharedApplication] cancelLocalNotification:notificationObject];
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
    // テスト用：通知時間（15秒後）
    //notificationObject.fireDate = [NSDate dateWithTimeIntervalSinceNow:(15)];
    // 通知時間 <= 現在時 なら次の日の同時刻を指定
    if ([[self readData:@"time"] timeIntervalSinceNow] <= 0) {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents* components =  [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay| NSCalendarUnitHour| NSCalendarUnitMinute)
                                                    fromDate:[self readData:@"time"]];
        components.day ++;
        NSDate* newDate = [calendar dateFromComponents:components];
        //UserDefaults保存用変数を上書き
        notificationDate = newDate;
        //UserDefaultsに新しい日時を上書き
        [self saveData:@"time"];
    }
    // 通知時間を設定
    notificationObject.fireDate = [self readData:@"time"];
    // 使用するカレンダー
    notificationObject.repeatCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    // 毎日繰り返す
    notificationObject.repeatInterval = NSCalendarUnitWeekday;
    // タイムゾーン
    notificationObject.timeZone = [NSTimeZone defaultTimeZone];
    // メッセージ
    notificationObject.alertBody = [NSString stringWithFormat:@"タップして%@の天気を確認", [self readData:@"place"]];
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


#pragma mark - NSUserDefaults
// NSUserDefaultsに初期値を登録する
//未使用
-(void)registerData:(NSString *)flag{
    // UserDefaults取得
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if([flag isEqualToString:@"switch"]){
        //test
        NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
        // KEY_Sというキーの初期値はhoge
        [defaults setObject:@"hoge" forKey:@"KEY_S"];
        //registerDefaultsメソッドを使用して取得したNSUserDefaultsに登録
        [ud registerDefaults:defaults];
    }else if([flag isEqualToString:@"place"]){
        
    }else if([flag isEqualToString:@"time"]){
        
    }
}
// NSUserDefaultsに保存・更新する
-(void)saveData:(NSString *)flag{
    // UserDefaults取得
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if([flag isEqualToString:@"switch"]){
        // スイッチの値をKEY_switchキーで保存
        //NSNumber *num = [NSNumber numberWithBool:notificationSwitch];
        [ud setBool:notificationSwitch forKey:@"KEY_switch"];
        [ud synchronize];  // NSUserDefaultsに即時反映させる
    }else if([flag isEqualToString:@"place"]){
        // 地名をKEY_placeキーで保存
        [ud setObject:placeName forKey:@"KEY_place"];
        [ud synchronize];
    }else if([flag isEqualToString:@"time"]){
        // 通知時間をKEY_timeキーで保存
        [ud setObject:notificationDate forKey:@"KEY_time"];
        [ud synchronize];
    }
}
// NSUserDefaultsからデータを読み込んで返す
-(id)readData:(NSString *)flag{
    // UserDefaults取得
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if([flag isEqualToString:@"switch"]){
        // KEY_switchの内容をid型として取得して返す
        return [ud objectForKey:@"KEY_switch"];
    }else if([flag isEqualToString:@"place"]){
        // KEY_placeの内容をNSString型として取得して返す
        return [ud stringForKey:@"KEY_place"];
    }else if([flag isEqualToString:@"time"]){
        // KEY_timeの内容をid型として取得して返す
        return [ud objectForKey:@"KEY_time"];
    }else{
        return nil;
    }
}
// NSUserDefaultsからデータを削除する
//未使用
-(void)deleteData:(NSString *)flag{
    // UserDefaults取得
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if([flag isEqualToString:@"switch"]){
        // KEY_switchを削除する
        [ud removeObjectForKey:@"KEY_switch"];
    }else if([flag isEqualToString:@"place"]){
        // KEY_placeを削除する
        [ud removeObjectForKey:@"KEY_place"];
    }else if([flag isEqualToString:@"time"]){
        // KEY_timeを削除する
        [ud removeObjectForKey:@"KEY_time"];
    }
}



#pragma mark - Other
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
