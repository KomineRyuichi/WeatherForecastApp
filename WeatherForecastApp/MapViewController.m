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
    
    //**test**//
    //mapView:regionDidChangeAnimated:が動いた回数
    int countGesture;
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
    //readDBで拡大と縮小のどちらかを判断するためにデルタ値を格納する(緯度経度のどちら片方で判別可能)
    double historyLatitudeDelta;
    
    //** DBtest **//
    //データベースのパス
    int MAP_NUMBER;
    NSString *MAP_JAPANESE_NAME;
    double MAP_LATITUDE;
    double MAP_LONGITUDE;
    int MAP_DISPLAY_PERMISSION_RANGE;
    //** DBtest **//
}
@end

@implementation MapViewController

#pragma mark - 	ViewController
- (void)viewDidLoad {
    NSLog(@"テストviewDidLoad：start");
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
    
    //初期値に合わせてhistoryLatitudeDeltaも初期化
    historyLatitudeDelta = 15;
    
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
    
    countGesture = 1;
    NSLog(@"テストviewDidLoad：finish");
    [self getScaleAndLocation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.visibleViewController.tabBarController.tabBar.hidden = NO;
}


#pragma mark - 	screen transition
//遷移直前に呼ばれる
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSLog(@"テストprepareForSegue：詳細画面に遷移");
    NSLog(@"テストprepareForSegue：地名 = %@",detailPlaceName);
    NSLog(@"テストprepareForSegue：緯度 = %f",detailLatitude);
    NSLog(@"テストprepareForSegue：経度 = %f",detailLongitude);
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
    NSLog(@"テストicon1：searchBarSearchButtonClicked:");
    NSLog(@"【%@】",_searchBar.text);
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = _searchBar.text;
    request.region = _mapView.region;
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:
     ^(MKLocalSearchResponse *response, NSError *error)
     {
         //検索結果の1件目の地点を拡大
         MKMapItem *item = [response.mapItems objectAtIndex:0];
         NSLog(@"テストicon1：(lat,lon)=(%f,%f)",item.placemark.coordinate.latitude,item.placemark.coordinate.longitude);
         CLLocationCoordinate2D searchLocation;
         MKCoordinateRegion searchRegion;
         // 表示する画面の中心として検索結果の緯度・軽度を設定
         searchLocation.latitude = item.placemark.coordinate.latitude;
         searchLocation.longitude = item.placemark.coordinate.longitude;
         
         //**test**//
         searchLocation.latitude = 38;
         searchLocation.longitude = 145;
         //**test**//
         
         [self.mapView setCenterCoordinate:searchLocation animated:YES];
         // 縮尺を設定
         searchRegion = self.mapView.region;
         searchRegion.center = searchLocation;
         // 検索結果を中心とし、どのくらい拡大するか設定
         searchRegion.span.latitudeDelta = 2;
         searchRegion.span.longitudeDelta = 2;
         [self.mapView setRegion:searchRegion animated:YES];
     }];
}
//縮尺と画面左上・右下の緯度・経度を取得する
-(void)getScaleAndLocation{
    NSLog(@"テストicon2：getScaleAndLocation");
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
    NSLog(@"テストicon3：readDB");
    NSLog(@"テストicon3：latitudeDelta = %f",zoomRegion.span.latitudeDelta);
    //** DBtest **//
    // (1)
    NSString *dbfile = @"Location.db";
    // データベースファイルを格納するために文書フォルダを取得
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:dbfile];
    NSLog(@"db path = %@", dbPath);
    // (2)
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
    } else {
        NSLog(@"DB file OK");
    }
    // (3)
    //データベースのパス
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    // (4)
    //データベース内のテーブルから表示したいカラムを選ぶ
    NSString *selectSql;
    if( zoomRegion.span.latitudeDelta < 5.66 ){
        selectSql = [NSString stringWithFormat:@"SELECT MAP_JAPANESE_NAME,MAP_LATITUDE,MAP_LONGITUDE FROM location WHERE MAP_DISPLAY_PERMISSION_RANGE = 100"];
    }else{
        selectSql = [NSString stringWithFormat:@"SELECT MAP_JAPANESE_NAME,MAP_LATITUDE,MAP_LONGITUDE FROM location WHERE MAP_DISPLAY_PERMISSION_RANGE = 500"];
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
        //[result stringForColumn:@"MAP_JAPANESE_NAME"]
    }
    [db close];
    
    
//    //縮尺・緯度・経度で絞り込む（https://akira-watson.com/iphone/sqlite.html）
//    //絞り込みの際にデータと比較する緯度・経度は下のようにnwCoordとseCoordから取得
//    //**test**//
//    NSLog(@"テストicon3(northWest latitude) : %f",nwCoord.latitude);
//    NSLog(@"テストicon3(northWest longitude) : %f",nwCoord.longitude);
//    NSLog(@"テストicon3(southEast latitude) : %f",seCoord.latitude);
//    NSLog(@"テストicon3(southEast longitude) : %f",seCoord.longitude);
    
    
    [resultArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [self doCommunication:resultArray count:idx];
    }];
    
}
//DBから取得したデータをパラメータとして、APIにリクエストを投げる
-(void)doCommunication:(NSArray *)array count:(NSUInteger)count{
    NSLog(@"テストicon4：doCommunication");
    NSString *placeName = [array[count] objectForKey:@"place"];
    latitude = [NSString stringWithFormat:@"%@",[array[count] objectForKey:@"lat"]];
    longitude = [NSString stringWithFormat:@"%@",[array[count] objectForKey:@"lon"]];
    double resultlat = [latitude doubleValue];
    double resultlon = [longitude doubleValue];
    NSString *origin = [NSString stringWithFormat:@"http://iwakamiy:0828sYs1129@api.openweathermap.org/data/2.5/weather?lat=%@&lon=%@&appid=a9a8461295cb8b16af35deb36ec27445",latitude,longitude];
    NSLog(@"テストicon4：origin = %@",origin);
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
                   // オフライン時アラート処理(未実装)
                   NSLog(@"Session Error:%@", error);
                   return;
               }else{
                   [self doParseData:data Place:placeName Lat:resultlat Lon:resultlon];
               }
           }];
    
    [task resume];
}
//JSON形式のレスポンスをパース、iconキーの値を取得
-(void)doParseData:(NSData*)data Place:(NSString*)place Lat:(double)lat Lon:(double)lon{
    NSLog(@"テストicon5：doParse");
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
    NSLog(@"アイコン:%@", iconNameString);
//    NSLog(@"アイコン:%@", [weather valueForKeyPath:@"icon"]);
    NSString *placeName = place;
    double resultlat = lat;
    double resultlon = lon;
    [self setWeatherIconPlace:placeName Lat:resultlat Lon:resultlon];
}
//ピンをセット
-(void)setWeatherIconPlace:(NSString*)place Lat:(double)lat Lon:(double)lon{
    NSLog(@"テストicon6：setWeatherIconLat:Lon:");
    CustomAnnotation* weatherIconAnnotation = [[CustomAnnotation alloc] init];
    NSLog(@"テストicon6：(lat,lon)=(%f,%f)",lat,lon);
    weatherIconAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon);
    weatherIconAnnotation.title = place;
    weatherIconAnnotation.subtitle = @"詳細画面へ";
    [self.mapView addAnnotation:weatherIconAnnotation];
}
//ピンを削除（縮小した時に呼ばれる）
-(void)deleteIcon{
    NSLog(@"テストicon7：deleteIcon");
    [self.mapView removeAnnotations:self.mapView.annotations];
    NSLog(@"テストicon7：FINISH deleteIcon");
}



#pragma mark - Annotation
//addAnnotationの後に呼ばれる
-(MKAnnotationView*)mapView:(MKMapView*)_mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    NSLog(@"テストAnnotation1：mapView:viewForAnnotation:");
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
    NSLog(@"テストAnnotation1：iconNameString = 「%@」",iconNameString);
//    NSLog(@"テストAnnotation1：icon = 「%@」",icon);
    //iconNameString = @"11d";
    weatherIconView.image = [UIImage imageNamed:iconNameString];
    // バルーン表示許可
    weatherIconView.canShowCallout = YES;
    // rightCalloutAccessoryViewにボタン追加
    weatherIconView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    // MKAnnotationViewに呼び出し元で定義したCustomAnnotationのインスタンスを追加
    weatherIconView.annotation = annotation;
    return weatherIconView;
}
//mapView:viewForAnnotation:の後に呼ばれる
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    NSLog(@"テストAnnotation2：mapView:didAddAnnotationViews");
    NSLog(@"************************ count = %d *****************************\n\n\n\n",
          countGesture);
    countGesture ++;
    [views enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        //enumerateObjectsUsingBlock:について
        //http://qiita.com/exilias/items/f8ebd0dfed493bb0e25a
    }];
}
//追加したボタンが押されたときに呼ばれる
-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    NSLog(@"テストAnnotation3：rightCalloutAccessoryViewのボタンが押されました！");
    //詳細画面に送る用の変数に地名、緯度・経度をセット
    detailPlaceName = view.annotation.title;
    detailLatitude = view.annotation.coordinate.latitude;
    detailLongitude = view.annotation.coordinate.longitude;
    [self performSegueWithIdentifier:@"goDetail" sender:self];
}



#pragma mark - button
//「縮尺を戻す」ボタン
-(void)pushResetScaleButton{
    NSLog(@"テストbutton1-1：pushResetScaleButton");
    gesture = @"resetScale";
//    [self deleteIcon];
    [self.mapView setCenterCoordinate:location animated:YES];
    [self.mapView setRegion:region animated:YES];
//    [self getScaleAndLocation];
    gesture = nil;
}
//「拡大」ボタン
-(void)pushZoomButton{
    NSLog(@"テストbutton2：pushZoomButton");
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
//http://developer.yahoo.co.jp/webapi/map/openlocalplatform/v1/iphonesdk/reference/YMKMapViewDelegate.html#mapviewregionwillchangeanimated
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    NSLog(@"*****************************************************");
    NSLog(@"テストregionDidChange：mapView:regionDidChangeAnimated:");
    // 天気アイコン全消し
    [self deleteIcon];
    [self getScaleAndLocation];
}



#pragma mark - MemoryWarning
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
