//
//  CenterViewController.m
//  BLEDemo
//
//  Created by pei on 2019/11/11.
//  Copyright © 2019 peipei. All rights reserved.
//

#import "CenterViewController.h"
#import "PPBLEManager.h"
#import "ConectViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface CenterViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) CBCentralManager *bleManager;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSMutableDictionary *dataDic;
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;//当前已经连接的外设
@property (nonatomic, strong) ConectViewController *connectVC;
@property (nonatomic, strong) CBCharacteristic *characteristic;//服务特征



@end

@implementation CenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"中心服务";
    self.bleManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.dataDic = [[NSMutableDictionary alloc] init];
    self.dataArray = [[NSMutableArray alloc] init];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor colorWithRed:244 green:244 blue:244 alpha:1];

    [self.view addSubview:self.tableView];
    //
    //    PPBLEManager *bleManager = [[PPBLEManager alloc] initWithBleQueue:nil];

        ConectViewController *connectVC = [[ConectViewController alloc] init];
        connectVC.view.frame = CGRectMake(0, 210, self.view.frame.size.width, self.view.frame.size.height - 300);
        [self addChildViewController:connectVC];
        [self.view addSubview:connectVC.view];
        
        [connectVC setSendActionBlock:^{
            [self sendMessageToPeripheral];
        }];
        self.connectVC = connectVC;
        
    //    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    //    [self.view addGestureRecognizer:gesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithRed:244 green:244 blue:244 alpha:1];
}

#pragma mark 蓝牙代理方法
//搜索外围设备
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    /*
     CBManagerStateUnknown = 0,
     CBManagerStateResetting,
     CBManagerStateUnsupported,
     CBManagerStateUnauthorized,
     CBManagerStatePoweredOff,
     CBManagerStatePoweredOn,
     */
    switch (central.state) {
        case CBManagerStatePoweredOn:
            [self.bleManager scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
            NSLog(@"链接状态---%ld",(long)central.state);
            break;
    }
}

//发现可连接的外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *name = [peripheral name];
    if (name && ![[self.dataDic allKeys] containsObject:name]) {
        
        NSLog(@"链接的账号-----%@ \n----%@",peripheral,central);
        [self.dataDic setObject:peripheral forKey:name];
        [self.tableView reloadData];
    }
}

//连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //连接成功-关闭扫描，避免资源浪费
    [central stopScan];
    self.connectedPeripheral = peripheral;
    peripheral.delegate = self;

    [peripheral discoverServices:nil];
    NSLog(@"连接成功-----%@",peripheral.name);

}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接失败-----%@",peripheral.name);
}

//获取外设的服务回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{

    CBService *service = nil;
    for (CBService *ser in peripheral.services) {
        service = ser;
        NSLog(@"服务ID----%@",ser.UUID);
    }
    if (service) {
        [peripheral discoverCharacteristics:NULL forService:service];
    }
}

//发现特征回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error
{
    self.characteristic = [service.characteristics firstObject];
    [peripheral setNotifyValue:YES forCharacteristic:self.characteristic];

        // 发送下行指令(发送一条)
    NSData *data = [@"我是你的小宝贝，小丫小宝贝~~唱" dataUsingEncoding:NSUTF8StringEncoding];
            // 将指令写入蓝牙
    [peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];

    [peripheral discoverDescriptorsForCharacteristic:self.characteristic];
}

//获取值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // characteristic.value就是蓝牙给我们的值(我这里是json格式字符串)
    NSData *jsonData = characteristic.value;
//    NSData *jsonData = [NSData dataUsingEncoding:NSUTF8StringEncoding];
    NSString *str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);  // 震动
    self.connectVC.receiveTextLabel.text = str;
    // 将字典传出去就可以使用了
}

//中心读取外设的实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
    } else {
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        NSLog(@"%@", characteristic);
        [self.bleManager cancelPeripheralConnection:peripheral];
    }
}


//给外设发送消息
- (void)sendMessageToPeripheral
{
    NSData *data = [self.connectVC.sendTextView.text dataUsingEncoding:NSUTF8StringEncoding];
    [self.connectedPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

//给外设发送消息成功回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"发送成功----%@",error);
}



//接受外设的消息





#pragma mark UItableViewDelegate && UItableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  self.dataDic.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    NSString *str = self.dataDic.allKeys[indexPath.row];
    cell.textLabel.text = str;
    if ([str isEqualToString:@"My dear"]) {
        cell.backgroundColor = [UIColor systemPinkColor];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:244 green:244 blue:244 alpha:1];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *keyStr = self.dataDic.allKeys[indexPath.row];
    //建立连接
    [self.bleManager connectPeripheral:self.dataDic[keyStr] options:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view resignFirstResponder];
}


@end
