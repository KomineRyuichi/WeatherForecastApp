//
//  NotificationViewController.m
//  WeatherForecastApp
//
//  Created by 岩上遥平 on 2016/09/25.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "NotificationViewController.h"
#import "ClosePickerView.h"
#import "SwitchTableViewCell.h"
#import "PlaceNameTableViewCell.h"
#import "TimeTableViewCell.h"
#import "DatePickerViewController.h"
#import "PlaceNameViewController.h"

@interface NotificationViewController ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
{
    UILocalNotification *notificationObject;
    NSString *placeName;
    NSNumber *placeLatitude;
    NSNumber *placeLongitude;
    NSDate *notificationDate;
    
    // セル
    UITableViewCell *cell;
    SwitchTableViewCell *onOffCell;
    PlaceNameTableViewCell *placeNameCell;
    TimeTableViewCell *timeCell;
    
    //UserDefaultsにスイッチの状態を知らせるための変数
    BOOL notificationSwitch;
    
    //UIDatePicker
    UIDatePicker *datePicker;
    
    // ツールバー
    UIToolbar *toolBar;
}
@property (nonatomic) ClosePickerView *closePickerView;
@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _notificationTableView.delegate = self;
    _notificationTableView.dataSource = self;
    self.notificationTableView.estimatedRowHeight = 73.0f;
    //カスタムセルを指定
    UINib *nib1 = [UINib nibWithNibName:@"SwitchTableViewCell" bundle:nil];
    [self.notificationTableView registerNib:nib1 forCellReuseIdentifier:@"notificationTableCell1"];
    UINib *nib2 = [UINib nibWithNibName:@"PlaceNameTableViewCell" bundle:nil];
    [self.notificationTableView registerNib:nib2 forCellReuseIdentifier:@"notificationTableCell2"];
    UINib *nib3 = [UINib nibWithNibName:@"TimeTableViewCell" bundle:nil];
    [self.notificationTableView registerNib:nib3 forCellReuseIdentifier:@"notificationTableCell3"];
    
    // DatePickerの設定
    datePicker = [[UIDatePicker alloc]init];
    [datePicker setDatePickerMode:UIDatePickerModeTime];
    [datePicker addTarget:self action:@selector(updateTextField:) forControlEvents:UIControlEventValueChanged];
    
    // ツールバー作成
    toolBar = [[UIToolbar alloc]init];
    toolBar.barStyle = UIBarStyleDefault;
    toolBar.translucent = YES;
    toolBar.tintColor = nil;
    [toolBar sizeToFit];
    
    //完了ボタン、spacer作成
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithTitle:@"完了" style:UIBarButtonItemStylePlain target:self action:@selector(pickerDoneClicked)];
    UIBarButtonItem *spacer1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *spacer2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    //ツールバーにボタンをセット
    [toolBar setItems:[NSArray arrayWithObjects:spacer1, spacer2, doneButton, nil]];
    
    
    // Pickerを閉じるためのView作成
    self.closePickerView = [[ClosePickerView alloc]initWithFrame:CGRectZero];
    self.closePickerView.target = self;
    self.closePickerView.action = @selector(hidePicker);
    self.closePickerView.backgroundColor = [UIColor blackColor];
    self.closePickerView.alpha = 0.1;
    [self.view addSubview:self.closePickerView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:{
            onOffCell = [_notificationTableView dequeueReusableCellWithIdentifier:@"notificationTableCell1"];
            onOffCell.onOffSwitch.on = [[self readData:@"switch"] boolValue];
            onOffCell.textLabel.font = [UIFont fontWithName:@"Arial" size:24];
            [onOffCell.onOffSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            onOffCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return onOffCell;
            break;
        }
        case 1:{
            placeNameCell = [_notificationTableView dequeueReusableCellWithIdentifier:@"notificationTableCell2"];
            placeNameCell.titlelabel.text = @"通知する地点";
            //Userdefaultsにデータがあるかどうかを判断
            NSString *placeText = [self readData:@"place"];
            if(placeText==nil){
                placeText = @"未設定";
            }
            placeNameCell.placeNameLabel.text = placeText;
            placeNameCell.textLabel.font = [UIFont fontWithName:@"Arial" size:24];
            placeNameCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return placeNameCell;
            break;
        }
        case 2:{
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
            timeCell.timeTextField.text = timeText;
            // inputViewにDatePickerをセット
            timeCell.timeTextField.inputView = datePicker;
            // toolBarをセット
            timeCell.timeTextField.inputAccessoryView = toolBar;
            timeCell.timeTextField.delegate = self;
            timeCell.timeTextField.font = [UIFont fontWithName:@"Arial" size:24];
            timeCell.selectionStyle = UITableViewCellSelectionStyleNone;
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
            [self performSegueWithIdentifier:@"toPlaceNameView" sender:self];
            break;
        case 2:
            break;
    }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
        PlaceNameViewController *placeNameViewController = segue.destinationViewController;
        placeNameViewController.dataBlocks = ^(NSString *text,NSNumber *latitude,NSNumber *longitude){
            placeNameCell.placeNameLabel.text = text;
            //通知用
            placeName = text;
            placeLatitude = latitude;
            placeLongitude = longitude;
            //UserDefaults
            [self saveData:@"place"];
            [self switchChanged:onOffCell.onOffSwitch];
        };
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
        }
    }else{
        // Offの時の処理
        notificationSwitch = switchParts.on;
        //UserDefaults
        [self saveData:@"switch"];
        // 通知のリセット
        [[UIApplication sharedApplication] cancelLocalNotification:notificationObject];
    }
}


#pragma mark - TextField
-(BOOL)textFieldShouldBeginEditing:(UITextView *)textView{
    // closePickerViewを画面サイズに広げる
    self.closePickerView.frame = [[UIScreen mainScreen] bounds];
    return YES;
}
-(void)updateTextField:(id)sender {
    //picker = (UIDatePicker *)sender;
}
-(void)pickerDoneClicked {
    UIDatePicker *picker = datePicker;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *dateStr = [formatter stringFromDate:picker.date];
    timeCell.timeTextField.text = dateStr;
    //UserDefaultsでの保存に使用
    notificationDate = picker.date;
    //UserDefaults
    [self saveData:@"time"];
    [self switchChanged:onOffCell.onOffSwitch];
    // closePickerViewのサイズをゼロにする
    self.closePickerView.frame = CGRectZero;
    // pickerを消す
    [timeCell.timeTextField resignFirstResponder];
}
-(void)hidePicker{
    // closePickerViewのサイズをゼロにする
    self.closePickerView.frame = CGRectZero;
    // pickerを消す
    [timeCell.timeTextField resignFirstResponder];
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
    [self createNotificationObject];
}
//②通知オブジェクトの生成と内容指定
-(void)createNotificationObject{
    // インスタンス生成
    notificationObject = [[UILocalNotification alloc] init];
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
    [self createSchedule];
}
//③スケジューリング
-(void)createSchedule{
    [[UIApplication sharedApplication] cancelLocalNotification:notificationObject];
    [[UIApplication sharedApplication] scheduleLocalNotification:notificationObject];
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
        [ud setObject:placeLatitude forKey:@"KEY_latitude"];
        [ud setObject:placeLongitude forKey:@"KEY_longitude"];
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
