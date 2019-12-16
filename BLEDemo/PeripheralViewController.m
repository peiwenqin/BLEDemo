//
//  PeripheralViewController.m
//  BLEDemo
//
//  Created by pei on 2019/11/9.
//  Copyright © 2019 peipei. All rights reserved.
//

#import "PeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "ConectViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface PeripheralViewController ()<CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, strong) ConectViewController *connectVC;


@end

@implementation PeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"外设服务";
    self.view.backgroundColor = [UIColor colorWithRed:244 green:244 blue:244 alpha:1];

    CBPeripheralManager *manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    self.peripheralManager = manager;
    
    ConectViewController *connectVC = [[ConectViewController alloc] init];
    connectVC.view.frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.height - 300);
    [self addChildViewController:connectVC];
    [self.view addSubview:connectVC.view];
    
    [connectVC setSendActionBlock:^{
        [self sendData];
    }];
    self.connectVC = connectVC;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithRed:244 green:244 blue:244 alpha:1];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBManagerStatePoweredOn) {
        //外设蓝牙打开，可进入连接状态
        [self setPeripheralCharacteristicService];
    } else {
        NSLog(@"蓝牙不可连接 ----%ld",(long)peripheral.state);
    }
}

//创建特征值和服务--中心设备搜索到可对应此连接进行通信
- (void)setPeripheralCharacteristicService
{
    //创建服务
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"ff11"] primary:YES];//primary--是否是初级（基础）的服务
    //创建特征
    /*
     大坑大坑大坑
     当value值不为nil的时候，只能设置只读状态，否则崩溃
     properties的读写属性要和peimissions匹配
     */
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"ff22"] properties:CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
    self.characteristic = characteristic;
    service.characteristics = @[characteristic];
    
    //将特征和服务提供给外设，调用代理（一个蓝牙可以注册多个服务。一个服务可以携带多个特征）
    [self.peripheralManager addService:service];
    
}

#pragma mark CBPeripheralManagerDelegate
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    //对于注册成功的服务，直接广播
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:@"ff11"]],CBAdvertisementDataLocalNameKey:@"My dear"}];
    
}

//开启广播的回调
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"广播数据----%@",error);
}

#pragma mark 数据交互
//中心设备请求读取数据
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"1111----%@",request.characteristic.value);
    //判断是否有权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    } else {
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

//中心设备请求写入数据
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    NSLog(@"收到中心设备的写入请求");
    //判断是否有写入的权限
    CBATTRequest *request = [requests firstObject];
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        CBMutableCharacteristic *charact = (CBMutableCharacteristic *)request.characteristic;
        charact.value = request.value;
        [self.peripheralManager respondToRequest:[requests firstObject] withResult:CBATTErrorSuccess];
    } else {
        [self.peripheralManager respondToRequest:[requests firstObject] withResult:CBATTErrorWriteNotPermitted];
    }
    for (CBATTRequest *request in requests) {
        NSData *data = request.characteristic.value;
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);  // 震动
        self.connectVC.receiveTextLabel.text = string;
    NSLog(@"2222----%@",request.characteristic.value);
    }
}


/*
 向中心设备发送数据
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *message = self.connectVC.sendTextView.text;
    [self.peripheralManager updateValue:[message dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:characteristic onSubscribedCentrals:nil];
}

//取消通知
 - (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
 {
     NSLog(@"关闭通知");
 }
 


- (void)sendData
{
    NSString *str = self.connectVC.sendTextView.text ? : @"I,m message!";
    [self.peripheralManager updateValue:[str dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
