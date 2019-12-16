//
//  PPBLEManager.m
//  BLEDemo
//
//  Created by 王俊 on 2019/11/5.
//  Copyright © 2019 peipei. All rights reserved.
//

#import "PPBLEManager.h"

@implementation PPBLEManager

- (instancetype)initWithBleQueue:(nullable dispatch_queue_t)queue
{
    static dispatch_once_t onceToken;
    __block PPBLEManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[PPBLEManager alloc] init];
        self.bleManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
    });
    return manager;
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

- (void)sendData:(NSData *)data
{
    
}

//发现可连接的外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *name = [peripheral name];
    
}


@end
