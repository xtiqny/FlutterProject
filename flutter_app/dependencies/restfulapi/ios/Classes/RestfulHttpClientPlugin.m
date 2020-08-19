//
//  RestfulHttpClientPlugin.m
//  Cloud189
//
//  Created by cocoDevil on 2019/9/9.
//  Copyright © 2019 21cn. All rights reserved.
//

#import "RestfulHttpClientPlugin.h"

/// 请求通道
#define Flutter_Native_Restful_HttpClient @"com.cn21.network.restfulapi/RestfulClientPlugin"
/// 创建请求
#define Method_Client_Http_Create @"create"
/// 关闭创建的请求
#define Method_Client_Http_Close @"close"
/// 执行请求
#define Method_Client_Http_Execute @"execute"
/// 取消进行的请求
#define Method_Client_Http_CancelRequest @"cancelRequest"
/// 绑定最后一个resetfulClientId
#define Resetful_Http_CurrentClientId @"resetfulHttpCurrentClientId"

static NSString *timeOut = @"connectTimeout";
static NSString *clientId = @"clientId";
static NSString *requestId = @"requestId";
static NSString *requestMethod = @"method";
static NSString *requestUrl = @"url";
static NSString *requestHead = @"headers";
static NSString *requestBody = @"body";

@interface RestfulHttpClientPlugin ()

@property (nonatomic, weak) NSObject<FlutterPluginRegistrar> *registrar;

/**
 自生成的clientId组
 */
@property (nonatomic, strong) NSMutableDictionary *mHttpClients;

/**
 请求任务列表
 */
@property (nonatomic, strong) NSMutableDictionary *mHttpCalls;

/**
 超时时间
 */
@property (nonatomic, assign) NSInteger timeout;

/**
 当前的id,默认从99开始
 */
@property (nonatomic, assign) NSInteger currentClientId;

@end

@implementation RestfulHttpClientPlugin

-(instancetype)init {
    if (self = [super init]) {
        self.currentClientId = 99;
    }
    return self;
}

+(NSString *)pluginChannelName {
    return Flutter_Native_Restful_HttpClient;
}

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
//    [self registerWithRegistrar:registrar];
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:Flutter_Native_Restful_HttpClient binaryMessenger: [registrar messenger]];
    RestfulHttpClientPlugin *httpClientPlugin = [[RestfulHttpClientPlugin alloc] init];
    [registrar addMethodCallDelegate:httpClientPlugin channel:channel];
}

-(void)registerChannelWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self.methodChannel = [FlutterMethodChannel methodChannelWithName:Flutter_Native_Restful_HttpClient binaryMessenger: [registrar messenger]];
    [registrar addMethodCallDelegate:self channel:self.methodChannel];
    self.registrar = registrar;
}

-(void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:Method_Client_Http_Create]) {
        [self creatWithFlutterMethodCall:call result:result];
    }else if ([call.method isEqualToString:Method_Client_Http_Close]){
        [self closeWithFlutterMethodCall:call result:result];
    }else if ([call.method isEqualToString:Method_Client_Http_Execute]){
        [self executeFlutterMethodCall:call result:result];
    }else if ([call.method isEqualToString:Method_Client_Http_CancelRequest]){
        [self cancelRequestFlutterMethodCall:call result:result];
    }else{
        NSLog(@"原生没有实现方法🔥🔥🔥🔥🔥%@🔥🔥🔥🔥🔥", call.method);
        result(@{@"statusMsg":@"iOS No Method"});
    }
}
/// clientId加入
-(void)creatWithFlutterMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (call.arguments) {
        NSLog(@"create:%@", call.arguments);
        NSDictionary *argDict = call.arguments;
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        CGFloat connectTimeout = [argDict.allKeys containsObject:@"http.connTimeout"] ? [argDict[@"http.connTimeout"] floatValue] : 30.0;
        CGFloat readTimeout = [argDict.allKeys containsObject:@"http.writeTimeout"] ? [argDict[@"http.writeTimeout"] floatValue] : 30.0;
        configuration.timeoutIntervalForResource = readTimeout;
        configuration.timeoutIntervalForRequest = connectTimeout;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        self.currentClientId++;
        [self.mHttpClients setObject:session forKey:@(self.currentClientId)];
        result(@(self.currentClientId));
    }else{
        result(@{@"statusMsg":@"argument is nil", @"statusCode":@(9999)});
    }
    
}
/// 移除clientId
-(void)closeWithFlutterMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (call.arguments) {
        NSInteger client_Id = [call.arguments integerValue];
        if ([self.mHttpClients.allKeys containsObject:@(client_Id)]) {
            [self.mHttpClients removeObjectForKey:@(client_Id)];
        }
        result(@{@"statusMsg":@"success", @"statusCode":@"0"});
    }else{
        result(@{@"statusMsg":@"argument is nil", @"statusCode":@(9999)});
    }
}
/// 执行对应的请求
-(void)executeFlutterMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (call.arguments) {
        NSDictionary *argDict = call.arguments;
        /// 处理header和body
        NSMutableURLRequest *request = [NSMutableURLRequest new];
        if ([argDict.allKeys containsObject:requestMethod]) {
            /// 方式
            request.HTTPMethod = argDict[requestMethod];
            /// URL
            request.URL = [NSURL URLWithString:argDict[requestUrl]];
            /// HEAD
            NSDictionary *headDict = argDict[requestHead];
            for (NSString *key in headDict) {
                [request setValue:headDict[key] forHTTPHeaderField:key];
            }
            /// BODY
            [request setHTTPBody:argDict[requestBody]];
        }
        /// 发起请求
        NSInteger client_id = [argDict[clientId] integerValue];
        if ([self.mHttpClients.allKeys containsObject:@(client_id)] && argDict[requestId]) {
            /// 绑定clientId
            NSURLSession *session = self.mHttpClients[@(client_id)];
            NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    NSMutableDictionary *errorDict = [NSMutableDictionary new];
                    //[errorDict setValuesForKeysWithDictionary:error.userInfo];
                    [errorDict setObject:@(error.code) forKey:@"statusCode"];
                    [errorDict setObject:error.localizedDescription forKey:@"statusMsg"];
                    result(errorDict);
                }else if(data){
                    NSMutableDictionary *successDict = [NSMutableDictionary new];
                    [successDict setObject:@(0) forKey:@"statusCode"];
                    [successDict setValue:@"success" forKey:@"statusMsg"];
                    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
                    [successDict setObject:urlResponse.allHeaderFields forKey:@"headers"];
                    [successDict setValue:@(data.length) forKey:@"bodyBinaryLength"];
                    [successDict setObject:data forKey:@"body"];
                    result(successDict);
                }else{
                    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
                    NSMutableDictionary *dict = [NSMutableDictionary new];
                    [dict setObject:@(urlResponse.statusCode) forKey:@"statusCode"];
                    [dict setObject:urlResponse.allHeaderFields forKey:@"headers"];
                    result(dict);
                }
            }];
            [self.mHttpCalls setObject:task forKey:argDict[requestId]];
            [task resume];
        }else{
            /// 没有这个clientId，不执行请求
            result(@{@"statusMsg":@"Wrong ClientId", @"statusCode":@(9999)});
        }
    }else{
        result(@{@"statusMsg":@"argument is nil", @"statusCode":@(9999)});
    }
}
/// 取消对应的请求
-(void)cancelRequestFlutterMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (call.arguments) {
        NSDictionary *argDict = call.arguments;
        NSInteger client_id = [argDict[clientId] integerValue];
        NSInteger request_id = [argDict[requestId] integerValue];
        if ([self.mHttpClients.allKeys containsObject:@(client_id)] && [self.mHttpCalls.allKeys containsObject:@(request_id)]) {
            NSURLSession *session = self.mHttpClients[@(client_id)];
            NSURLSessionTask *curtask = self.mHttpCalls[@(request_id)];
            __weak typeof(self) wSelf = self;
            [session getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
                __strong typeof(wSelf) self = wSelf;
                BOOL findClientAndRequest_id = NO;
                for (NSURLSessionTask *task in tasks) {
                    if (task.taskIdentifier == curtask.taskIdentifier) {
                        [task cancel];
                        [self.mHttpCalls removeObjectForKey:@(request_id)];
                        findClientAndRequest_id = YES;
                        result(@{@"statusMsg":@"success", @"statusCode":@"0"});
                        break;
                    }
                }
                if (!findClientAndRequest_id) {
                    result(@{@"statusMsg":@"didn't find equal requestId", @"statusCode":@(9999)});
                }
            }];
        }else{
            result(@{@"statusMsg":@"Wrong clientId or requestId", @"statusCode":@(9999)});
        }
    }else{
        result(@{@"statusMsg":@"argument is nil", @"statusCode":@(9999)});
    }
}

#pragma mark:--GETTER--
-(NSMutableDictionary *)mHttpClients {
    if (!_mHttpClients) {
        _mHttpClients = [NSMutableDictionary new];
    }
    return _mHttpClients;
}

-(NSMutableDictionary *)mHttpCalls {
    if (!_mHttpCalls) {
        _mHttpCalls = [NSMutableDictionary new];
    }
    return _mHttpCalls;
}

@end
