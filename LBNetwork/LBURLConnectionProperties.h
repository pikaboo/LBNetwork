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
//  LBConnectionErrorProperties.h
//  LBNetwork
//
//  Created by Lena Brusilovski on on 8/18/14.
//

#import <Foundation/Foundation.h>
#import "LBDeserializer.h"


@protocol LBConnectionErrorHandler <NSObject>

-(BOOL)shouldDisplayActivityIndicatorForRequest:(NSURLRequest*)request;
-(BOOL)shouldDisplayErrorForResponse:(LBServerResponse *)response;

@optional

-(BOOL)shouldRetryRequest:(NSError *)error forCurrentTry:(NSInteger)currentTry;

-(NSString *)titleForErrorForResponse:(LBServerResponse *)response;
-(NSString *)messageForErrorForResponse:(LBServerResponse *)response;
-(NSString *)titleForOKButtonErrorMessageForResponse:(LBServerResponse *)response;


@end
@interface LBURLConnectionProperties : NSObject

typedef enum{
    LogLevelNone = 0,
    LogLevelDebug
}LogLevel;

@property (nonatomic,assign)NSInteger maxRetryCount;
@property (nonatomic,assign)LogLevel logLevel;
@property (nonatomic,assign)id<LBConnectionErrorHandler>errorHandler;
-(id<LBDeserializer>)registerDeserializer:(id<LBDeserializer>)deserializer forContentType:(NSString *)contentType;
-(id<LBDeserializer>)deserializerForContentType:(NSString *)contentType;
@end
