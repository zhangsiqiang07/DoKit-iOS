//
//  DoraemonNetFlowListViewController.h
//  DoraemonKit
//
//  Created by yixiang on 2018/4/11.
//

#import "DoraemonBaseViewController.h"

@interface DoraemonNetFlowListViewController : DoraemonBaseViewController

/// 注册域名过滤列表（黑名单模式：过滤掉这些域名的请求）
/// @param domains 域名数组，例如：@[@"example.com", @"api.example.com"]
+ (void)registerFilterDomains:(NSArray<NSString *> *)domains;

/// 清除域名过滤列表
+ (void)clearFilterDomains;

/// 获取当前注册的域名过滤列表
+ (NSArray<NSString *> *)filterDomains;

@end
