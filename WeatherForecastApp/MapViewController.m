//
//  MapViewController.m
//  WeatherForecastApp
//
//  Created by PCK-135-087 on 2016/09/06.
//  Copyright © 2016年 PCK-135-089. All rights reserved.
//

#import "MapViewController.h"
#import "CustomAnnotation.h"
#import "DetailViewController.h"
#import "FMDatabase.h"
#import "APICommunication.h"

@interface MapViewController ()<MKMapViewDelegate,UISearchBarDelegate>
{
    //緯度・経度の初期値を設定
    CLLocationCoordinate2D location;
    //縮尺の初期値を設定
    MKCoordinateRegion region;
    //拡大・縮小ボタンを押した時のデルタ値を格納
    MKCoordinateRegion zoomRegion;
    //Assetsの名前を格納する文字列
    NSString *iconNameString;
    //動作判別に使う
    NSString *gesture;
    //詳細画面に送る地名、緯度・経度
    NSString *detailPlaceName;
    double detailLatitude;
    double detailLongitude;
    //sql文に反映するレンジ
    NSString *range;
    //viewWillAppear:の初回判定に使用
    BOOL first;
    //オフラインアラート表示の際に、ボタン操作による拡大縮小かどうかを判定
    BOOL pushButton;
    //オフライン状態かどうかを判定
    BOOL off;
    //各アラート
    UIAlertController *alertController;
}
@end

@implementation MapViewController

#pragma mark - 	ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"お天気マップ";
    _searchBar.delegate = self;
    _searchBar.keyboardType = UIKeyboardTypeURL;
    
    // Delegate をセット
    _mapView.delegate = self;
    // 表示する画面の中心の緯度・軽度を設定
    location.latitude = 37.68154;
    location.longitude = 137.2754;
    [self.mapView setCenterCoordinate:location animated:YES];
    // 縮尺を設定
    region = self.mapView.region;
    region.center = location;
    //Deltaは緯度・経度の絶対値の差
    region.span.latitudeDelta = 15;
    region.span.longitudeDelta = 8;
    [self.mapView setRegion:region animated:YES];
    // viewに追加
    [self.view addSubview:self.mapView];
    
    //ボタンを最前面に移動
    [self.view bringSubviewToFront:_resetScaleButton];
    [self.view bringSubviewToFront:_zoomOutButton];
    [self.view bringSubviewToFront:_zoomInButton];
    
    [self getScaleAndLocation];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = NO;
    //一度オフラインで呼ばれた後、オンライン状態で再び呼ばれた場合にもアイコンを表示するために通信
    //初回起動時は実行しない（viewDidLoadでもgetScaleAndLocationを呼ぶのでアラートが2回出ちゃうから）
    if(!first){
        [self deleteIcon];
        [self getScaleAndLocation];
    }
    first = NO;
}



#pragma mark - 	screen transition
//遷移直前に呼ばれる
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    //destinationViewControllerで詳細画面を指定
    DetailViewController *detailViewController = segue.destinationViewController;
    //詳細画面に緯度・経度を渡す
    detailViewController.placeName = detailPlaceName;
    detailViewController.detailLatitude = detailLatitude;
    detailViewController.detailLongitude = detailLongitude;
}



#pragma mark - icon
//検索を行う(キーボードの検索ボタンタップ時に呼ばれる)
-(void)searchBarSearchButtonClicked:(UISearchBar*)searchBar{
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = _searchBar.text;
    request.region = _mapView.region;
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:
     ^(MKLocalSearchResponse *response, NSError *error)
     {
         if(error) {
             // 検索失敗時アラート処理
             NSString *keyWord;
             //オフライン時に検索をかけると「オフラインです。」と表示する
             if(off){
                 keyWord = @"オフラインです。";
             }else{
                 keyWord = @"結果が見つかりませんでした。";
             }
             alertController = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@",keyWord] preferredStyle:UIAlertControllerStyleAlert];
             [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
             }]];
             [self presentViewController:alertController animated:YES completion:nil];
         }else{
             //検索結果の1件目の地点を拡大
             MKMapItem *item = [response.mapItems objectAtIndex:0];
             CLLocationCoordinate2D searchLocation;
             MKCoordinateRegion searchRegion;
             // 検索結果の緯度・軽度を画面の中心に設定
             searchLocation.latitude = item.placemark.coordinate.latitude;
             searchLocation.longitude = item.placemark.coordinate.longitude;[self.mapView setCenterCoordinate:searchLocation animated:YES];
             // 縮尺を設定
             searchRegion = self.mapView.region;
             searchRegion.center = searchLocation;
             // 検索結果を中心とし、どのくらい拡大するか設定
             searchRegion.span.latitudeDelta = 2;
             searchRegion.span.longitudeDelta = 2;
             [self.mapView setRegion:searchRegion animated:YES];
         }
     }];
}
//縮尺と画面左上・右下の緯度・経度を取得する
-(void)getScaleAndLocation{
    //縮尺を取得
    //画面左上の緯度・経度を取得
    CGPoint northWest = CGPointMake(_mapView.bounds.origin.x,_mapView.bounds.origin.y);
    CLLocationCoordinate2D nwCoord = [_mapView convertPoint:northWest toCoordinateFromView:_mapView];
    //画面右下の緯度・経度を取得
    CGPoint southEast = CGPointMake(_mapView.bounds.origin.x+_mapView.bounds.size.width,_mapView.bounds.origin.y+_mapView.bounds.size.height);
    CLLocationCoordinate2D seCoord = [_mapView convertPoint:southEast toCoordinateFromView:_mapView];
    //拡大・縮小ボタンから直接呼ばれた時はzoomRegionに値を格納、mapView:regionDidChangeAnimated:から呼ばれた場合はreadDBを実行
    if([gesture isEqualToString:@"pushButton"]){
        zoomRegion = self.mapView.region;
        //現在の画面のデルタ値を取得
        zoomRegion.span.latitudeDelta = (nwCoord.latitude - seCoord.latitude);
        zoomRegion.span.longitudeDelta = (seCoord.longitude - nwCoord.longitude);
        //gestureをリセット
        gesture = nil;
    }else{
        [self readDBnwCoord:nwCoord seCoord:seCoord];
    }
}
//条件を満たすデータをFMDBから読み込む。条件を満たすデータがあれば直前の動作に応じてdoCommunicationかdeleteIconを呼ぶ。
-(void)readDBnwCoord:(CLLocationCoordinate2D)nwCoord seCoord:(CLLocationCoordinate2D)seCoord{
    zoomRegion.span.latitudeDelta = (nwCoord.latitude - seCoord.latitude);
    
    //** DB **//
    NSString *dbfile = @"Location.db";
    // データベースファイルを格納するために文書フォルダを取得
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:dbfile];
    BOOL checkDb;
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    checkDb = [fileManager fileExistsAtPath:dbPath];// データベースファイルを確認
    if(!checkDb){
        // ファイルが無い場合はコピー
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:dbfile];
        checkDb = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        if(!checkDb){
#if DEBUG
            // Erroの場合
            NSLog(@"Copy error = %@", defaultDBPath);
#endif
        }
    }
    //データベースのパス
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    //データベース内のテーブルから表示したいカラムを選ぶ
    NSString *selectSql;
    //rangeを満たし、画面内に入っている地点を呼び出すsql文
    selectSql = [NSString stringWithFormat:@"SELECT MAP_JAPANESE_NAME,MAP_LATITUDE,MAP_LONGITUDE FROM location WHERE MAP_DISPLAY_PERMISSION_RANGE = %@ AND (MAP_LATITUDE BETWEEN %f AND %f) AND (MAP_LONGITUDE BETWEEN %f AND %f)",range,seCoord.latitude,nwCoord.latitude,nwCoord.longitude,seCoord.longitude];
    //デルタ値で県を読み込むか市を読み込むかを判断
    if(zoomRegion.span.latitudeDelta < 5.66){
        range = @"100";
    }else{
        range = @"500";
    }
    
    //DBからの読み込み処理
    [db open];
    FMResultSet *result = [db executeQuery:selectSql];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSArray *keyArray = [[NSArray alloc] initWithObjects:@"place",@"lat",@"lon", nil];
    while ([result next]) {
        NSArray *geoArray = [[NSArray alloc] initWithObjects:[result stringForColumn:@"MAP_JAPANESE_NAME"],[NSNumber numberWithDouble:[result doubleForColumn:@"MAP_LATITUDE"]],[NSNumber numberWithDouble:[result doubleForColumn:@"MAP_LONGITUDE"]], nil];
        NSDictionary *resultDic = [[NSDictionary alloc] initWithObjects:geoArray forKeys:keyArray];
        [resultArray addObject:resultDic];
    }
    [db close];
    
    [resultArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [self doCommunication:resultArray count:idx];
    }];
}
//DBから取得したデータを通信クラスに渡す、レスポンスを引数にパースメソッド呼び出し
-(void)doCommunication:(NSArray *)array count:(NSUInteger)count{
    NSString *placeName = [array[count] objectForKey:@"place"];
    double resultlat = [[NSString stringWithFormat:@"%@",[array[count] objectForKey:@"lat"]] doubleValue];
    double resultlon = [[NSString stringWithFormat:@"%@",[array[count] objectForKey:@"lon"]] doubleValue];
    //通信
    APICommunication *apiCommunication = [[APICommunication alloc] init];
    [apiCommunication startAPICommunication:@"weather" :resultlat :resultlon :^(NSDictionary *jsonData, BOOL networkOfflineFlag, BOOL apiRegulationsFlag) {
        if(networkOfflineFlag){
            //ボタン操作による拡大縮小の場合のみアラートを表示
            if(pushButton){
                //オフライン状態を示すフラグをオン
                off = YES;
                alertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"オフラインです。" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }]];
                [self presentViewController:alertController animated:YES completion:nil];
                //ボタン操作かどうかを判別するフラグをオフ
                pushButton = NO;
            }
        }else{
            if(apiRegulationsFlag){
                alertController = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"API規制です。" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }]];
                [self presentViewController:alertController animated:YES completion:nil];
            }else{
                //オフライン状態を示すフラグをオフ
                off = NO;
                [self doParseData:jsonData Place:placeName Lat:resultlat Lon:resultlon];
            }
        }
    }];
}
//コールバックで呼ばれる。パース済みのデータからiconキーの値を取得
-(void)doParseData:(NSDictionary*)data Place:(NSString*)place Lat:(double)lat Lon:(double)lon{
    NSArray *weather = [data objectForKey:@"weather"];
    NSDictionary *icon = [weather objectAtIndex:0];
    iconNameString = [icon objectForKey:@"icon"];
    NSString *placeName = place;
    [self setWeatherIconPlace:placeName Lat:lat Lon:lon];
}
//ピンをセット
-(void)setWeatherIconPlace:(NSString*)place Lat:(double)lat Lon:(double)lon{
    CustomAnnotation* weatherIconAnnotation = [[CustomAnnotation alloc] init];
    weatherIconAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon);
    weatherIconAnnotation.title = place;
    weatherIconAnnotation.subtitle = @"詳細画面へ";
    [self.mapView addAnnotation:weatherIconAnnotation];
}
//ピンを削除
-(void)deleteIcon{
    [self.mapView removeAnnotations:self.mapView.annotations];
}



#pragma mark - Annotation
//addAnnotationの後に呼ばれる
-(MKAnnotationView*)mapView:(MKMapView*)_mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    MKAnnotationView *weatherIconView;
    // 再利用可能なannotationがあるかどうかを判断するための識別子を定義
    NSString* identifier = @"Pin";
    // dequeueReusableAnnotationViewWithIdentifierで"Pin"という識別子の使いまわせるannotationがあるかチェック
    weatherIconView = (MKAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    // 使い回しができるannotationがない場合、annotationの初期化
    if(weatherIconView == nil) {
        weatherIconView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
    }
    // 画像セット
    weatherIconView.image = [UIImage imageNamed:iconNameString];
    // バルーン表示許可
    weatherIconView.canShowCallout = YES;
    // rightCalloutAccessoryViewにボタン追加
    weatherIconView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    // MKAnnotationViewに呼び出し元で定義したCustomAnnotationのインスタンスを追加
    weatherIconView.annotation = annotation;
    return weatherIconView;
}
//追加したボタンが押されたときに呼ばれる
-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    //詳細画面に送る用の変数に地名、緯度・経度をセット
    detailPlaceName = view.annotation.title;
    detailLatitude = view.annotation.coordinate.latitude;
    detailLongitude = view.annotation.coordinate.longitude;
    [self performSegueWithIdentifier:@"goDetail" sender:self];
}



#pragma mark - button
//「縮尺を戻す」ボタン
- (IBAction)pushResetScaleButton:(UIButton *)sender {
    pushButton = YES;
    [self.mapView setCenterCoordinate:location animated:YES];
    [self.mapView setRegion:region animated:YES];
}
//「−」ボタン
- (IBAction)pushZoomOutButton:(UIButton *)sender {
    gesture = @"pushButton";
    pushButton = YES;
    [self getScaleAndLocation];
    //取得したデルタ値を広げることで地図を縮小
    zoomRegion.span.latitudeDelta += 2;
    zoomRegion.span.longitudeDelta += 2;
    [self.mapView setRegion:zoomRegion animated:YES];
}
//「＋」ボタン
- (IBAction)pushZoomInButton:(UIButton *)sender {
    gesture = @"pushButton";
    pushButton = YES;
    [self getScaleAndLocation];
    //取得したデルタ値を縮めることで地図を拡大
    zoomRegion.span.latitudeDelta -= 2;
    zoomRegion.span.longitudeDelta -= 2;
    [self.mapView setRegion:zoomRegion animated:YES];
}



#pragma mark - regionDidChange
//地図の表示領域が変更された時に呼ばれる
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    // 天気アイコン全消し
    [self deleteIcon];
    [self getScaleAndLocation];
}



#pragma mark - MemoryWarning
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
