//
//  DoraemonNetFlowHttpModel.m
//  DoraemonKit
//
//  Created by yixiang on 2018/4/11.
//

#import "DoraemonNetFlowHttpModel.h"
#import "DoraemonNetFlowManager.h"
#import "NSURLRequest+Doraemon.h"
#import "DoraemonUrlUtil.h"

@implementation DoraemonNetFlowHttpModel

+ (void)dealWithResponseData:(NSData *)responseData response:(NSURLResponse*)response request:(NSURLRequest *)request complete:(void (^)(DoraemonNetFlowHttpModel *model))complete {
    DoraemonNetFlowHttpModel *httpModel = [[DoraemonNetFlowHttpModel alloc] init];
    //request
    httpModel.request = request;
    httpModel.requestId = request.requestId;
    httpModel.url = [request.URL absoluteString];
    httpModel.method = request.HTTPMethod;
    //response
    httpModel.mineType = response.MIMEType;
    httpModel.response = response;
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        httpModel.statusCode = [NSString stringWithFormat:@"%d",(int)httpResponse.statusCode];
    } else {
        httpModel.statusCode = @"0";
    }
    httpModel.responseData = responseData;
    httpModel.responseBody = [DoraemonUrlUtil convertJsonFromData:responseData];
    httpModel.totalDuration = [NSString stringWithFormat:@"%fs",[[NSDate date] timeIntervalSince1970] - request.startTime.doubleValue];
    httpModel.downFlow = [NSString stringWithFormat:@"%lli",[DoraemonUrlUtil getResponseLength:(NSHTTPURLResponse *)response data:responseData]];
    
    // 使用同步方式获取请求体，确保 complete 回调总是被调用
    NSData *httpBody = nil;
    if (request.HTTPBody) {
        httpBody = request.HTTPBody;
    } else if ([request.HTTPMethod isEqualToString:@"POST"] && request.HTTPBodyStream) {
        // 对于流式请求体，使用异步方式
        [[DoraemonNetFlowManager shareInstance] httpBodyFromRequest:request bodyCallBack:^(NSData *body) {
            httpModel.requestBody = [DoraemonUrlUtil convertJsonFromData:body];
            NSUInteger length = [DoraemonUrlUtil getHeadersLengthWithRequest:request] + [body length];
            httpModel.uploadFlow = [NSString stringWithFormat:@"%zi", length];
            complete(httpModel);
        }];
        return;
    }
    
    // 同步处理请求体
    httpModel.requestBody = [DoraemonUrlUtil convertJsonFromData:httpBody];
    NSUInteger length = [DoraemonUrlUtil getHeadersLengthWithRequest:request] + [httpBody length];
    httpModel.uploadFlow = [NSString stringWithFormat:@"%zi", length];
    complete(httpModel);
}

@end
