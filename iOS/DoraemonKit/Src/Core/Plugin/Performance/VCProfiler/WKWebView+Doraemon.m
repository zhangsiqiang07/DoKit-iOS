//
//  WKWebView+Doraemon.m
//  DoraemonKit
//
//  Created by didi on 2020/2/7.
//

#import "WKWebView+Doraemon.h"
#import <objc/runtime.h>
#import "NSObject+Doraemon.h"

#if DoraemonWithDiDi
#import "DoraemonHealthManager.h"
#endif

@implementation WKWebView (Doraemon)

+ (void)load{
    [self doraemon_swizzleInstanceMethodWithOriginSel:@selector(loadRequest:) swizzledSel:@selector(doraemon_loadRequest:)];
}

- (WKNavigation *)doraemon_loadRequest:(NSURLRequest *)request{
    WKNavigation *navigation = [self doraemon_loadRequest:request];
    NSString *urlString = request.URL.absoluteString;
#if DoraemonWithDiDi
    [[DoraemonHealthManager sharedInstance] openH5Page:urlString];
#endif
    return navigation;
}

@end
