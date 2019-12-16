//
//  ConectViewController.m
//  BLEDemo
//
//  Created by 王俊 on 2019/11/5.
//  Copyright © 2019 peipei. All rights reserved.
//

#import "ConectViewController.h"

@interface ConectViewController ()

@end

@implementation ConectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)sendAction:(id)sender {
    if (self.sendActionBlock) {
        self.sendActionBlock();
    }
}


@end
