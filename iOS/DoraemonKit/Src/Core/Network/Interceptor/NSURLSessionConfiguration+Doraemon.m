//
//  NSURLSessionConfiguration+Doraemon.m
//  DoraemonKit
//
//  Created by yixiang on 2018/7/2.
//

#import "NSURLSessionConfiguration+Doraemon.h"
#import "DoraemonNSURLProtocol.h"
#import "NSObject+Doraemon.h"
#import "DoraemonNetFlowManager.h"
#import "DoraemonCacheManager.h"


@implementation NSURLSessionConfiguration (Doraemon)

+ (void)load{
    // 保留网络拦截功能，仅禁用上报逻辑
    [[self class] doraemon_swizzleClassMethodWithOriginSel:@selector(defaultSessionConfiguration) swizzledSel:@selector(doraemon_defaultSessionConfiguration)];
    [[self class] doraemon_swizzleClassMethodWithOriginSel:@selector(ephemeralSessionConfiguration) swizzledSel:@selector(doraemon_ephemeralSessionConfiguration)];
}

+ (NSURLSessionConfiguration *)doraemon_defaultSessionConfiguration{
    NSURLSessionConfiguration *configuration = [self doraemon_defaultSessionConfiguration];
    [configuration addDoraemonNSURLProtocol];
    return configuration;
}

+ (NSURLSessionConfiguration *)doraemon_ephemeralSessionConfiguration{
    NSURLSessionConfiguration *configuration = [self doraemon_ephemeralSessionConfiguration];
    [configuration addDoraemonNSURLProtocol];
    return configuration;
}

- (void)addDoraemonNSURLProtocol {
    if ([self respondsToSelector:@selector(protocolClasses)]
        && [self respondsToSelector:@selector(setProtocolClasses:)]) {
        // 确保 protocolClasses 不为 nil，初始化为空数组
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray: self.protocolClasses ?: @[]];
        Class protoCls = DoraemonNSURLProtocol.class;
        
        // 如果已存在，先移除（确保重新插入到第一位，保证优先级最高）
        if ([urlProtocolClasses containsObject:protoCls]) {
            [urlProtocolClasses removeObject:protoCls];
        }
        
        // 插入到第一位（确保优先级最高）
        [urlProtocolClasses insertObject:protoCls atIndex:0];
        self.protocolClasses = urlProtocolClasses;
    }
}

@end
