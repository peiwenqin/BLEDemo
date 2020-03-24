# BLEDemo
探究iOS基本的蓝牙通信功能<br>
蓝牙分传统蓝牙（蓝牙 2.0，经典蓝牙）和BLE（低功耗蓝牙，蓝牙 4.0），BLE 将三种规格集一体，包括蓝牙技术，高速技术和低能耗技术。<br>
蓝牙不能同时作为外设和中心设备，在某次连接中只能当担一种角色。<br>
使用蓝牙需要在 info.plist文件添加NSBluetoothPeripheralUsageDescription请求允许蓝牙权限使用

###蓝牙俩种模式的连接
####CBCentralManager 中心模式
1、建立中心角色

```
#import <CoreBluetooth/CoreBluetooth.h>

@interface CenterViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, strong) CBPeripheral *connectedPeripheral;//当前已经连接的外设
@property (nonatomic, strong) CBCharacteristic *characteristic;//服务特征
@end

@implementation CenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"中心服务";
    self.bleManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

@end

```

2、扫描外设

```
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

```
3、发现外设

```
//发现可连接的外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *name = [peripheral name];
    if (name && ![[self.dataDic allKeys] containsObject:name]) {
        NSLog(@"链接的账号-----%@ \n----%@",peripheral,central);
    }
}

```

4、连接外设，连接失败；连接断开；连接成功

```
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

//连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接失败-----%@",peripheral.name);
}

```

5、扫描外设的服务，发现并获取外设服务---这是外设的特性，外设的服务决定了中心设备的控制功能

```
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

```

6、扫描外设对应服务的特征，给对应的特征写入数据

```
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

```

7、订阅特征的通知，根据特征读取数据---即读取外设返回的数据

```
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

```

####CBPeripheralManager 外设模式
因为苹果设备的安全性和封闭性,苹果设备不能通过与其他设备蓝牙链接进行文件传输等功能,所以在iOS与蓝牙开发的编程中是CBCentralMannager 中心模式编程居多.<br>

1、建立外设角色

```
#import <CoreBluetooth/CoreBluetooth.h>

@interface PeripheralViewController ()<CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;

@end

@implementation PeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"外设服务";
    CBPeripheralManager *manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    self.peripheralManager = manager;
 }    
 
 //检查外设的蓝牙是否打开
 - (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBManagerStatePoweredOn) {
        //外设蓝牙打开，可进入连接状态
        [self setPeripheralCharacteristicService];
    } else {
        NSLog(@"蓝牙不可连接 ----%ld",(long)peripheral.state);
    }
}

@end

```

2、设置本地外设的服务和特征

```
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

```

3、发布外设和特征--即广播外设的特征(这里设置特征ID为“ff11”，特征名为“My dear”)

```

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

//取消通知
 - (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
 {
     NSLog(@"关闭通知");
 }


```

4、中心设备读写请求的处理

```
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


```

6、发送更新的特征值，订阅中心

```
- (void)sendData
{
    NSString *str = self.connectVC.sendTextView.text ? : @"I,m message!";
    [self.peripheralManager updateValue:[str dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
    
}

```

**本文根据蓝牙的通信功能写了一个不需网络通过蓝牙传送数据的小通信 demo，需要俩个设备一个充当中心设备，另一个充当外设，俩个设备即可以连接，实现蓝牙的通信功能**<br>
[demo地址](https://github.com/peiwenqin/BLEDemo)
