//
//  ViewController.m
//  BLEDemo
//
//  Created by 王俊 on 2019/11/4.
//  Copyright © 2019 peipei. All rights reserved.
//

#import "ViewController.h"
#import "CenterViewController.h"
#import "PeripheralViewController.h"

#define screenWidth  self.view.frame.size.width
#define screenHeight self.view.frame.size.height

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"蓝牙通信";
//    [centerBtn setTitle:@"中心设备" forState:UIControlStateNormal];
    UIImageView *imageV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg1"]];
    imageV.contentMode = UIViewContentModeCenter;
    imageV.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:imageV];
    
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(20, screenHeight - 200, screenWidth-40, 80)];
    lab.text = @"请用俩设备选择以下俩角色，开始你们的通信吧，小黄鸭进入后请选择My dear这个设备才能和你的dear通信哦！";
    lab.numberOfLines = 0;
    [self.view addSubview:lab];
    
    UIButton *centerBtn = [[UIButton alloc] initWithFrame:CGRectMake(70, screenHeight - 100, 100, 100)];
    [centerBtn setBackgroundImage:[UIImage imageNamed:@"duck"] forState:UIControlStateNormal];
    [centerBtn setBackgroundImage:[UIImage imageNamed:@"duck"] forState:UIControlStateHighlighted];
//    [centerBtn setBackgroundColor:[UIColor redColor]];
    centerBtn.tag = 10;
    [centerBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:centerBtn];
    
    UIButton *peripheralBtn = [[UIButton alloc] initWithFrame:CGRectMake(190, screenHeight - 100, 100, 100)];
    peripheralBtn.tag = 20;
    [peripheralBtn setBackgroundImage:[UIImage imageNamed:@"pig"] forState:UIControlStateNormal];
    [peripheralBtn setBackgroundImage:[UIImage imageNamed:@"pig"] forState:UIControlStateHighlighted];
//    [peripheralBtn setTitle:@"外设" forState:UIControlStateNormal];
//    [peripheralBtn setBackgroundColor:[UIColor purpleColor]];
    [peripheralBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:peripheralBtn];
}

- (void)btnAction:(UIButton *)sender
{

    if (sender.tag == 10) {
        CenterViewController *vc = [[CenterViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        PeripheralViewController *vc = [[PeripheralViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
