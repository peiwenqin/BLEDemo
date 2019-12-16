//
//  ConectViewController.h
//  BLEDemo
//
//  Created by 王俊 on 2019/11/5.
//  Copyright © 2019 peipei. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConectViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *sendTextView;
@property (weak, nonatomic) IBOutlet UILabel *receiveTextLabel;

@property (nonatomic, copy) void(^sendActionBlock)();


@end

NS_ASSUME_NONNULL_END
