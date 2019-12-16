//
//  PPBLEManager.h
//  BLEDemo
//
//  Created by 王俊 on 2019/11/5.
//  Copyright © 2019 peipei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPBLEManager : NSObject<CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *bleManager;
@property (nonatomic, copy) void(^scanAvalibleDeviceBlock)(NSArray *dicveArray);

- (instancetype)initWithBleQueue:(nullable dispatch_queue_t)queue;

//发送数据
- (void)sendData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
