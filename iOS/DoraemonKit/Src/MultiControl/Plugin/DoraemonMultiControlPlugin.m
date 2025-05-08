//
//  DoraemonMultiControlPlugin.m
//  DoraemonKit-DoraemonKit
//
//  Created by litianhao on 2021/7/12.
//

#import "DoraemonMultiControlPlugin.h"
#import "DoraemonHomeWindow.h"
#import "DoraemonDefine.h"
#import "DoraemonManager.h"
#import "DoraemonMCViewController.h"
#import "DoraemonMCClient.h"
#import "DoraemonMCServer.h"


@implementation DoraemonMultiControlPlugin

- (void)pluginDidLoad{
    DoraemonMCViewController *toolVC = [DoraemonMCViewController new];
    [DoraemonHomeWindow openPlugin:toolVC];
}

@end
