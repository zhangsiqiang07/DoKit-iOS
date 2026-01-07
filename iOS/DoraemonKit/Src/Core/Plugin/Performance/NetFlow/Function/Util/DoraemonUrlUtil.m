//
//  DoraemonUrlUtil.m
//  DoraemonKit
//
//  Created by yixiang on 2018/4/23.
//

#import "DoraemonUrlUtil.h"
#import "DoraemonNetFlowManager.h"

@implementation DoraemonUrlUtil

+ (NSString *)convertJsonFromData:(NSData *)data{
    if (!data) {
        return nil;
    }
    NSString *jsonString = nil;
    
    // 先尝试直接读取为字符串，这样可以保持原始 JSON 中的浮点数精度
    NSString *originalString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (originalString) {
        // 验证是否是有效的 JSON（通过尝试解析，但不使用解析结果）
        NSError *parseError = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (jsonObject && !parseError) {
            // 是有效的 JSON，直接美化原始字符串，保持所有数字的原始精度
            jsonString = [self prettyPrintJSON:originalString];
        } else {
            // 不是有效的 JSON，直接返回原始字符串
            jsonString = originalString;
        }
    } else {
        // 无法解析为 UTF-8 字符串，尝试使用 NSJSONSerialization（会丢失精度，但至少能显示）
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
            jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
            // NSJSONSerialization escapes forward slashes. We want pretty json, so run through and unescape the slashes.
            jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        } else {
            jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return jsonString;
}

// 美化 JSON 字符串，保持原始数字精度（不重新解析）
+ (NSString *)prettyPrintJSON:(NSString *)jsonString {
    if (!jsonString) {
        return nil;
    }
    
    // 移除首尾空白
    NSString *trimmed = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSMutableString *result = [NSMutableString string];
    NSInteger indentLevel = 0;
    NSInteger length = trimmed.length;
    BOOL inString = NO;
    BOOL escapeNext = NO;
    
    for (NSInteger i = 0; i < length; i++) {
        unichar c = [trimmed characterAtIndex:i];
        
        if (escapeNext) {
            [result appendFormat:@"%C", c];
            escapeNext = NO;
            continue;
        }
        
        if (c == '\\') {
            [result appendFormat:@"%C", c];
            escapeNext = YES;
            continue;
        }
        
        if (c == '"') {
            [result appendFormat:@"%C", c];
            inString = !inString;
            continue;
        }
        
        if (inString) {
            // 在字符串内，直接追加
            [result appendFormat:@"%C", c];
        } else {
            // 在字符串外，处理格式化
            switch (c) {
                case '{':
                case '[':
                    [result appendFormat:@"%C\n", c];
                    indentLevel++;
                    [result appendString:[self indentString:indentLevel]];
                    break;
                case '}':
                case ']':
                    indentLevel--;
                    [result appendString:@"\n"];
                    [result appendString:[self indentString:indentLevel]];
                    [result appendFormat:@"%C", c];
                    break;
                case ',':
                    [result appendFormat:@"%C\n", c];
                    [result appendString:[self indentString:indentLevel]];
                    break;
                case ':':
                    [result appendFormat:@"%C ", c];
                    break;
                case ' ':
                case '\n':
                case '\r':
                case '\t':
                    // 忽略空白字符（我们会在需要的地方添加）
                    break;
                default:
                    [result appendFormat:@"%C", c];
                    break;
            }
        }
    }
    
    return result;
}

// 生成缩进字符串
+ (NSString *)indentString:(NSInteger)level {
    return [@"" stringByPaddingToLength:level * 2 withString:@" " startingAtIndex:0];
}

+ (NSDictionary *)convertDicFromData:(NSData *)data{
    if (!data) {
        return nil;
    }
    NSDictionary *jsonObj = nil;
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if ([NSJSONSerialization isValidJSONObject:jsonObject]){
        jsonObj = jsonObject;
    }else{
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!str) return jsonObj;
        NSArray *componentsArray =  [str componentsSeparatedByString:@"&"];
        NSMutableDictionary *dic = @{}.mutableCopy;
        [componentsArray enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray *keyValues =  [obj componentsSeparatedByString:@"="];
            if (keyValues.count == 2) {
                [dic setValue:keyValues.lastObject forKey:keyValues.firstObject];
            }
        }];
        if (dic.allKeys.count > 0) {
            jsonObj = dic.copy;
        }
    }
    return jsonObj;
}
+ (void)requestLength:(NSURLRequest *)request callBack:(void (^)(NSUInteger))callBack {
    NSUInteger headersLength = [self getHeadersLengthWithRequest:request];
    [[DoraemonNetFlowManager shareInstance] httpBodyFromRequest:request bodyCallBack:^(NSData *body) {
        NSUInteger bodyLength = [body length];
        callBack(headersLength + bodyLength);
    }];
}

+ (NSUInteger)getHeadersLengthWithRequest:(NSURLRequest *)request {
    NSDictionary<NSString *, NSString *> *headerFields = request.allHTTPHeaderFields;
    NSDictionary<NSString *, NSString *> *cookiesHeader = [self getCookies:request];
    if (cookiesHeader.count) {
        NSMutableDictionary *headerFieldsWithCookies = [NSMutableDictionary dictionaryWithDictionary:headerFields];
        [headerFieldsWithCookies addEntriesFromDictionary:cookiesHeader];
        headerFields = [headerFieldsWithCookies copy];
    }
    return [self getHeadersLength:headerFields];
}

+ (NSUInteger)getHeadersLength:(NSDictionary *)headers {
    NSUInteger headersLength = 0;
    if (headers) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:headers
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
        headersLength = data.length;
    }
    
    return headersLength;
}

+ (NSDictionary<NSString *, NSString *> *)getCookies:(NSURLRequest *)request {
    NSDictionary<NSString *, NSString *> *cookiesHeader;
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray<NSHTTPCookie *> *cookies = [cookieStorage cookiesForURL:request.URL];
    if (cookies.count) {
        cookiesHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    }
    return cookiesHeader;
}

+ (int64_t)getResponseLength:(NSHTTPURLResponse *)response data:(NSData *)responseData{
    int64_t responseLength = 0;
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary<NSString *, NSString *> *headerFields = httpResponse.allHeaderFields;
        NSUInteger headersLength = [self getHeadersLength:headerFields];
        
        int64_t contentLength = 0.;
        if(httpResponse.expectedContentLength != NSURLResponseUnknownLength){
            contentLength = httpResponse.expectedContentLength;
        }else{
            contentLength = responseData.length;
        }
        
        responseLength = headersLength + contentLength;
    }
    return responseLength;
}

@end
