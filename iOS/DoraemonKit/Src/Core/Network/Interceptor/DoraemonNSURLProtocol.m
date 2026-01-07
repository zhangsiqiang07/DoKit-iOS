//
//  DoraemonNSURLProtocol.m
//  DoraemonKit
//
//  Created by yixiang on 2018/4/11.
//

#import "DoraemonNSURLProtocol.h"
#import "DoraemonNetFlowHttpModel.h"
#import "DoraemonNetFlowDataSource.h"
#import "DoraemonNetFlowManager.h"
#import "DoraemonURLSessionDemux.h"
#import "DoraemonNetworkInterceptor.h"
#import "DoraemonManager.h"
#import "DoraemonDefine.h"
#import "DoraemonUrlUtil.h"
#import "UIViewController+Doraemon.h"

#if DoraemonWithDiDi
#import "DoraemonMockManager.h"
#endif

static NSString * const kDoraemonProtocolKey = @"doraemon_protocol_key";

@interface DoraemonNSURLProtocol()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSError *error;

@property (atomic, strong, readwrite) NSThread *clientThread;
@property (atomic, copy,   readwrite) NSArray *modes;
@property (atomic, strong, readwrite) NSURLSessionDataTask *task;

@end

@implementation DoraemonNSURLProtocol

+ (DoraemonURLSessionDemux *)sharedDemux{
    static dispatch_once_t      sOnceToken;
    static DoraemonURLSessionDemux *sDemux;
    dispatch_once(&sOnceToken, ^{
        NSURLSessionConfiguration *config;
        config = [NSURLSessionConfiguration defaultSessionConfiguration];
        sDemux = [[DoraemonURLSessionDemux alloc] initWithConfiguration:config];
    });
    return sDemux;
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task {
    NSURLRequest *request = task.currentRequest;
    return request == nil ? NO : [self canInitWithRequest:request];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    NSString *urlString = request.URL.absoluteString ?: @"";
    NSString *method = request.HTTPMethod ?: @"GET";
    BOOL isHistoryList = [urlString containsString:@"historyList"] || [urlString containsString:@"petVoice/historyList"];
    
    // 调试日志：特别关注 historyList 请求
    if (isHistoryList) {
        DoKitLog(@"🔍 [DoraemonNSURLProtocol] ========== historyList 请求检测开始 ==========");
        DoKitLog(@"🔍 [DoraemonNSURLProtocol] URL: %@", urlString);
        DoKitLog(@"🔍 [DoraemonNSURLProtocol] Method: %@", method);
        DoKitLog(@"🔍 [DoraemonNSURLProtocol] Headers: %@", request.allHTTPHeaderFields ?: @{});
    }
    
    // 检查是否已被标记（避免循环拦截）
    if ([NSURLProtocol propertyForKey:kDoraemonProtocolKey inRequest:request]) {
        if (isHistoryList) {
            DoKitLog(@"❌ [DoraemonNSURLProtocol] historyList 请求已被标记，跳过拦截（避免循环）");
        }
        return NO;
    }
    
    // 检查拦截器是否已启用
    BOOL shouldIntercept = [DoraemonNetworkInterceptor shareInstance].shouldIntercept;
    if (!shouldIntercept) {
        if (isHistoryList) {
            DoKitLog(@"❌ [DoraemonNSURLProtocol] historyList 请求拦截失败: shouldIntercept = NO");
            DoKitLog(@"❌ [DoraemonNSURLProtocol] 提示：请确保 DoKit 网络监控已开启");
        }
        return NO;
    }
    
    // 检查协议类型
    NSString *scheme = request.URL.scheme ?: @"";
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) {
        if (isHistoryList) {
            DoKitLog(@"❌ [DoraemonNSURLProtocol] historyList 请求拦截失败: scheme = %@ (不是 http/https)", scheme);
        }
        return NO;
    }
    
    // 已移除 multipart/form-data 过滤，允许拦截文件上传请求
    // NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
    // if (contentType && [contentType containsString:@"multipart/form-data"]) {
    //     return NO;
    // }
    
//    if ([self ignoreRequest:request]) {
//        return NO;
//    }
    
    if (isHistoryList) {
        DoKitLog(@"✅ [DoraemonNSURLProtocol] historyList 请求将被拦截: %@", urlString);
        DoKitLog(@"✅ [DoraemonNSURLProtocol] ========== historyList 请求检测通过 ==========");
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kDoraemonProtocolKey inRequest:mutableReqeust];
    
#if DoraemonWithDiDi
    if ([[DoraemonMockManager sharedInstance] needMock:request]) {
        NSString *mockDomain = [DoraemonManager shareInstance].mockDomain ? [DoraemonManager shareInstance].mockDomain : @"https://mock.dokit.cn/";
        NSString *mockSceneUrl = [mockDomain stringByAppendingString:@"api/app/scene/%@"];
        NSString *sceneId = [[DoraemonMockManager sharedInstance] getSceneId:request];
        NSString *urlString = [NSString stringWithFormat:mockSceneUrl, sceneId];
        DoKitLog(@"MOCK URL == %@",urlString);
        mutableReqeust = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [DoraemonToastUtil showToastBlack:[NSString stringWithFormat:@"mock url = %@",request.URL.absoluteURL] inView:[UIViewController rootViewControllerForKeyWindow].view];
        });

    }
#endif
    
    return [mutableReqeust copy];
}

- (void)handleFromSelect{
    if(DoraemonWeakNetwork_Delay == [[DoraemonNetworkInterceptor shareInstance].weakDelegate weakNetSelecte]){
        DoKitLog(@"yd Delay Net");//此处有dispatch_get_main_queue，无法使用switch
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([[DoraemonNetworkInterceptor shareInstance].weakDelegate delayTime] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.task resume];
        });
    }else if(DoraemonWeakNetwork_WeakSpeed == [[DoraemonNetworkInterceptor shareInstance].weakDelegate weakNetSelecte]){
        DoKitLog(@"yd WeakUpFlow Net");
        [[DoraemonNetFlowManager shareInstance] httpBodyFromRequest:self.request bodyCallBack:^(NSData *body) {
            [[DoraemonNetworkInterceptor shareInstance].weakDelegate handleWeak:body isDown:NO];
            [self.task resume];
        }];
    }else{
        [self.task resume];
    }
}

- (BOOL)needLoading{
    BOOL result = YES;
    if ([DoraemonNetworkInterceptor shareInstance].weakDelegate){
        if(DoraemonWeakNetwork_OutTime == [[DoraemonNetworkInterceptor shareInstance].weakDelegate weakNetSelecte]){
            DoKitLog(@"yd Outtime Net");
            [self.client URLProtocol:self didFailWithError:[[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSURLErrorTimedOut userInfo:nil]];
            result = NO;
        }else if(DoraemonWeakNetwork_Break == [[DoraemonNetworkInterceptor shareInstance].weakDelegate weakNetSelecte]){
            DoKitLog(@"yd Break Net");
            [self.client URLProtocol:self didFailWithError:[[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil]];
            result = NO;
        }
    }
    return result;
}

- (void)startLoading{
    NSMutableURLRequest *   recursiveRequest;
    NSMutableArray *        calculatedModes;
    NSString *              currentMode;
    
    assert(self.clientThread == nil);
    assert(self.task == nil);
    assert(self.modes == nil);
    
    NSString *urlString = self.request.URL.absoluteString ?: @"";
    BOOL isHistoryList = [urlString containsString:@"historyList"] || [urlString containsString:@"petVoice/historyList"];
    
    if (isHistoryList) {
        DoKitLog(@"🚀 [DoraemonNSURLProtocol] historyList 请求开始加载: %@", urlString);
    }
    
    calculatedModes = [NSMutableArray array];
    [calculatedModes addObject:NSDefaultRunLoopMode];
    currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if ( (currentMode != nil) && ! [currentMode isEqual:NSDefaultRunLoopMode] ) {
        [calculatedModes addObject:currentMode];
    }
    self.modes = calculatedModes;
    assert([self.modes count] > 0);
    
    recursiveRequest = [[self request] mutableCopy];
    assert(recursiveRequest != nil);
    
    self.clientThread = [NSThread currentThread];
    self.data = [NSMutableData data];
    self.startTime = [[NSDate date] timeIntervalSince1970];
    self.task = [[[self class] sharedDemux] dataTaskWithRequest:recursiveRequest delegate:self modes:self.modes];
    assert(self.task != nil);
    
    if (isHistoryList) {
        DoKitLog(@"✅ [DoraemonNSURLProtocol] historyList 请求任务已创建，taskIdentifier: %lu", (unsigned long)self.task.taskIdentifier);
    }
    
    if([DoraemonNetworkInterceptor shareInstance].weakDelegate){
        [self handleFromSelect];
    }else{
        [self.task resume];
    }
}

- (void)stopLoading{
    assert(self.clientThread != nil);
    assert([NSThread currentThread] == self.clientThread);
    
    NSString *urlString = self.request.URL.absoluteString ?: @"";
    BOOL isHistoryList = [urlString containsString:@"historyList"] || [urlString containsString:@"petVoice/historyList"];
    
    if (isHistoryList) {
        NSTimeInterval duration = [[NSDate date] timeIntervalSince1970] - self.startTime;
        DoKitLog(@"🏁 [DoraemonNSURLProtocol] historyList 请求加载完成: %@", urlString);
        DoKitLog(@"🏁 [DoraemonNSURLProtocol] 耗时: %.3f 秒，数据大小: %lu 字节", duration, (unsigned long)self.data.length);
        if (self.error) {
            DoKitLog(@"❌ [DoraemonNSURLProtocol] 错误: %@", self.error.localizedDescription);
        } else {
            DoKitLog(@"✅ [DoraemonNSURLProtocol] 请求成功");
        }
    }
    
    [[DoraemonNetworkInterceptor shareInstance] handleResultWithData: self.data
                                                            response: self.response
                                                             request:self.request
                                                               error:self.error
                                                           startTime:self.startTime];
    
    if (self.task != nil) {
        [self.task cancel];
        self.task = nil;
    }
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    assert([NSThread currentThread] == self.clientThread);
    self.response = response;
    if([self needLoading]){
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    assert([NSThread currentThread] == self.clientThread);
    if ([DoraemonNetworkInterceptor shareInstance].weakDelegate) {
        if(DoraemonWeakNetwork_WeakSpeed == [[DoraemonNetworkInterceptor shareInstance].weakDelegate weakNetSelecte]){
            DoKitLog(@"yd WeakDownFlow Net");
            [[DoraemonNetworkInterceptor shareInstance].weakDelegate handleWeak:data isDown:YES];
        }
    }
    [self.data appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    assert([NSThread currentThread] == self.clientThread);
    if (error) {
        self.error = error;
        [self.client URLProtocol:self didFailWithError:error];
    }else if([self needLoading]){
        [self.client URLProtocolDidFinishLoading:self];
    }
}

//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
//    assert([NSThread currentThread] == self.clientThread);
//    //判断服务器返回的证书类型, 是否是服务器信任
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
//        //强制信任
//        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
//        completionHandler(NSURLSessionAuthChallengeUseCredential, card);
//    }
//}

// 去掉一些我们不关心的链接, 与UIWebView的兼容还是要好好考略一下
+ (BOOL)ignoreRequest:(NSURLRequest *)request{
    NSString *pathExtension = [request.URL.absoluteString pathExtension];
    //NSArray *blackList = @[@"",@"",@""];
    if (pathExtension.length > 0) {
        return YES;
    }
    return NO;
}

@end
