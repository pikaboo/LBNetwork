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

//  LBServerResponse.h
//  LBNetwork
//
//  Created by Lena Brusilovski on 1/12/14.
//

#import "LBNetwork.h"
#import "LBDeserializer.h"
@interface LBServerResponse : NSObject

@property (nonatomic,strong)id output;

@property (nonatomic,assign)NSInteger statusCode;
@property (nonatomic,strong)NSDictionary *headers;
@property (nonatomic,assign)NSString *cookie;
@property (nonatomic,assign)NSError *error;
@property (nonatomic,strong)NSData *rawResponseData;
@property (nonatomic,strong)NSString *rawResponseString;
@property (nonatomic,strong)NSURL *requestURL;
@property (nonatomic,assign)NSInteger currentRequestTryCount;
@property (nonatomic,strong)LBServerRequest *request;

+ (instancetype)handleServerResponse:(NSHTTPURLResponse *)rawResponse
        request:(LBServerRequest *)request
        data:(NSData *)data
        deserializer:(id<LBDeserializer>)deserializer
        error:(NSError *)error;

- (void)setResponseData:(NSData *)data;
@end

@interface NSData (LBServerResponse)
-(NSString *)toString;
@end
