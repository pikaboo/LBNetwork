/*
 * Copyright (c) 2014-present, Lena Brusilovski. All rights reserved.
 *
 * You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 * copy, modify, and distribute this software in source code or binary form for use.
 *
 *
 * This copyright notice shall be included in all copies or substantial portions of the software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

//
//  LBConnectionErrorProperties.m
//  LBNetwork
//
//  Created by Lena Brusilovski on 8/18/14.
//


#import "LBNetwork.h"
#define kDefaultDeserializer @"DefaultDeserializer"
@interface LBDictionaryDeserializer :NSObject <LBDeserializer>


@end

@implementation LBDictionaryDeserializer

-(id)deserialize:(NSData *)data toClass:(Class)clz{
    if(!data)
        return data;
    
    id  ret = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return ret;
}

@end

@interface LBJavaScriptDeserializer : NSObject <LBDeserializer>

@end

@implementation LBJavaScriptDeserializer
-(id)deserialize:(NSData *)data toClass:(Class)clz{
    return [data toString];
}

@end
@interface LBURLConnectionProperties()<LBConnectionErrorHandler,LBResponseTypeResolver>

@property (nonatomic,strong)NSMutableDictionary *registeredDeserializers;
@end

@implementation LBURLConnectionProperties

-(id)init{
    self = [super init];
    if(self) {
        self.registeredDeserializers = [[NSMutableDictionary alloc]init];
        LBDictionaryDeserializer *dictionaryDeserializer = [[LBDictionaryDeserializer alloc]init];
        LBJavaScriptDeserializer *javaScriptDeserializer = [[LBJavaScriptDeserializer alloc]init];
        [self registerDeserializer:dictionaryDeserializer forContentType:kDefaultDeserializer];
        [self registerDeserializer:javaScriptDeserializer forContentType:ContentTypeApplicationJavaScript];
        self.errorHandler = self;
        self.responseTypeResolver = self;
    }
    return self;
}

-(BOOL)shouldRetryRequest:(NSError *)error forCurrentTry:(NSInteger)currentTry{
    return currentTry<self.maxRetryCount;
}


-(BOOL)shouldDisplayActivityIndicatorForRequest:(NSURLRequest *)request{
    return YES;
}

-(BOOL)shouldDisplayErrorForResponse:(LBServerResponse *)response{
    return  response.statusCode>kHTTPStatusCodeBadRequest && [[UIApplication sharedApplication]applicationState] == UIApplicationStateActive;
}

-(NSString *)messageForErrorForResponse:(LBServerResponse *)response{
    return [[response error]localizedDescription];
}

-(NSString *)titleForErrorForResponse:(LBServerResponse *)response{
    return  @"Server Error";
}

-(NSString *)titleForOKButtonErrorMessageForResponse:(LBServerResponse *)response{
    return @"OK";
}


-(id<LBDeserializer>)registerDeserializer:(id<LBDeserializer>)deserializer forContentType:(NSString *)contentType{
    id<LBDeserializer> prev = [self.registeredDeserializers objectForKey:contentType];
    [self.registeredDeserializers setObject:deserializer forKey:contentType];
    return prev;
}

-(id<LBDeserializer>)deserializerForContentType:(NSString *)contentType{
    id<LBDeserializer> prev = [self.registeredDeserializers objectForKey:contentType];
    if (!prev) {
        return [self.registeredDeserializers objectForKey:kDefaultDeserializer];
    }
    return prev;
}

-(LBResponseType)responseType:(LBServerResponse *)response{
    if (response.statusCode>=kHTTPStatusCodeOK && response.statusCode<kHTTPStatusCodeMultipleChoices) {
        return LBResonseTypeSuccess;
    }
    return LBResponseTypeFail;
}

@end


