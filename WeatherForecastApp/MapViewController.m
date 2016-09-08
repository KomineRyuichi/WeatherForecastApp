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

@interface MapViewController ()<MKMapViewDelegate>
{
    //緯度・経度の初期値を設定
    CLLocationCoordinate2D location;
    //縮尺の初期値を設定
    MKCoordinateRegion region;
    //拡大・縮小ボタンを押した時のデルタ値を格納
    MKCoordinateRegion zoomRegion;
    //URLに突っ込む緯度経度
    NSString *latitude;
    NSString *longitude;
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
}
@end

@implementation MapViewController

#pragma mark - 	ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"お天気マップ";
    _searchBar.delegate = self;
    _searchBar.placeholder = @"地名を入力してください";
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
    
    //「縮尺を戻す」ボタン
    UIButton *resetScaleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    resetScaleButton.frame = CGRectMake(10, 650, 100, 30);
    resetScaleButton.backgroundColor = [UIColor lightGrayColor];
    [resetScaleButton setTitle:@"縮尺を戻す" forState:UIControlStateNormal];
    [resetScaleButton addTarget:self action:@selector(pushResetScaleButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resetScaleButton];
    //「拡大」ボタン
    UIButton *zoomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    zoomButton.frame = CGRectMake(375, 650, 30, 30);
    zoomButton.backgroundColor = [UIColor lightGrayColor];
    [zoomButton setTitle:@"＋" forState:UIControlStateNormal];
    [zoomButton addTarget:self action:@selector(pushZoomButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:zoomButton];
    //「縮小」ボタン
    UIButton *zoomOutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    zoomOutButton.frame = CGRectMake(340, 650, 30, 30);
    zoomOutButton.backgroundColor = [UIColor lightGrayColor];
    [zoomOutButton setTitle:@"−" forState:UIControlStateNormal];
    [zoomOutButton addTarget:self action:@selector(pushZoomOutButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:zoomOutButton];
    
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
             UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"検索結果が見つかりません" preferredStyle:UIAlertControllerStyleAlert];
             [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
             }]];
             [self presentViewController:alertController animated:YES completion:nil];
             NSLog(@"Search Error:%@", error);
             return;
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
    //拡大・縮小ボタンから呼ばれた時はzoomRegionに値を格納、それ以外はreadDBを実行
    if([gesture isEqualToString:@"pushButton"]){
        zoomRegion = self.mapView.region;
        //現在の画面のデルタ値を取得
        zoomRegion.span.latitudeDelta = (nwCoord.latitude - seCoord.latitude);
        zoomRegion.span.longitudeDelta = (seCoord.longitude - nwCoord.longitude);
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
            // Erroの場合
            NSLog(@"Copy error = %@", defaultDBPath);
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
//DBから取得したデータをパラメータとして、APIにリクエストを投げる
-(void)doCommunication:(NSArray *)array count:(NSUInteger)count{
    NSString *placeName = [array[count] objectForKey:@"place"];
    latitude = [NSString stringWithFormat:@"%@",[array[count] objectForKey:@"lat"]];
    longitude = [NSString stringWithFormat:@"%@",[array[count] objectForKey:@"lon"]];
    double resultlat = [latitude doubleValue];
    double resultlon = [longitude doubleValue];
    NSString *origin = [NSString stringWithFormat:@"http://iwakamiy:0828sYs1129@api.openweathermap.org/data/2.5/weather?lat=%@&lon=%@&appid=a9a8461295cb8b16af35deb36ec27445",latitude,longitude];
    NSURL* url = [NSURL URLWithString:origin];
    
    //**　dataTaskWithRequest:requestだとJSONじゃなくてHTMLが取得される
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    //**（dataTaskWithURL:url）（dataTaskWithRequest:request）
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task =
    [session dataTaskWithURL:url
           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
               if(error) {
                   // オフライン時アラート処理
                   UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"⚠︎" message:@"ネットワークに接続されていません" preferredStyle:UIAlertControllerStyleAlert];
                   [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                   }]];
                   [self presentViewController:alertController animated:YES completion:nil];
                   return;
               }else{
                   [self doParseData:data Place:placeName Lat:resultlat Lon:resultlon];
               }
           }];
    
    [task resume];
}
//JSON形式のレスポンスをパース、iconキーの値を取得
-(void)doParseData:(NSData*)data Place:(NSString*)place Lat:(double)lat Lon:(double)lon{
    // JSONをパース
    NSError *error;
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    //エラー処理
    if(error){
        NSLog(@"%@", [error localizedDescription]);
    }
    NSArray *weather = [jsonData objectForKey:@"weather"];
    NSDictionary *icon = [weather objectAtIndex:0];
    iconNameString = [icon objectForKey:@"icon"];
    NSString *placeName = place;
    double resultlat = lat;
    double resultlon = lon;
    [self setWeatherIconPlace:placeName Lat:resultlat Lon:resultlon];
}
//ピンをセット
-(void)setWeatherIconPlace:(NSString*)place Lat:(double)lat Lon:(double)lon{
    CustomAnnotation* weatherIconAnnotation = [[CustomAnnotation alloc] init];
    weatherIconAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon);
    weatherIconAnnotation.title = place;
    weatherIconAnnotation.subtitle = @"詳細画面へ";
    [self.mapView addAnnotation:weatherIconAnnotation];
}
//ピンを削除（縮小した時に呼ばれる）
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
-(void)pushResetScaleButton{
    gesture = @"resetScale";
    [self.mapView setCenterCoordinate:location animated:YES];
    [self.mapView setRegion:region animated:YES];
    gesture = nil;
}
//「拡大」ボタン
-(void)pushZoomButton{
    gesture = @"pushButton";
    [self getScaleAndLocation];
    //取得したデルタ値を縮めることで地図を拡大
    zoomRegion.span.latitudeDelta -= 2;
    zoomRegion.span.longitudeDelta -= 2;
    [self.mapView setRegion:zoomRegion animated:YES];
    gesture = nil;
}
//「縮小」ボタン
-(void)pushZoomOutButton{
    gesture = @"pushButton";
    [self getScaleAndLocation];
    //取得したデルタ値を広げることで地図を縮小
    zoomRegion.span.latitudeDelta += 2;
    zoomRegion.span.longitudeDelta += 2;
    [self.mapView setRegion:zoomRegion animated:YES];
    gesture = nil;
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
