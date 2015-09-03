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
//  LBHTTPSClient.h
//  LBNetwork
//
//  Created by Lena Brusilovski on 3/13/14.
//


#import "LBURLConnection.h"
#import "LBServerRequest.h"
@class LBServerResponse;
@class LBURLConnectionProperties;
@class UIImage;
/**
 * HTTP Request methods
 */
extern NSString* const kMethodGET;
extern NSString* const kMethodPOST;
extern NSString* const kMethodPUT;
extern NSString* const kMethodDELETE;
/**
 * Content-type strings
 */
extern NSString* const ContentTypeAutomatic;
extern NSString* const ContentTypeJSON;
extern NSString* const ContentTypeWWWEncoded;

extern NSString* const DataContentTypeImage;
extern NSString* const DataContentTypeVideo;

@interface LBHTTPSClient:NSObject<NSURLConnectionDelegate>



@property (nonatomic,assign)NSStringEncoding defaultTextEncoding;
@property (nonatomic,assign)NSURLRequestCachePolicy defaultCachePolicy;
@property (nonatomic,assign)int defaultTimeoutInSeconds;
@property (nonatomic,assign)BOOL doesControlIndicator;
@property (nonatomic,assign)NSString *requestContentType;
@property (nonatomic,strong)LBURLConnectionProperties *connectionProperties;


+(instancetype)sharedClient;
-(void)sendRequest:(LBServerRequest *)request;
-(void)asyncUploadRequestData:(LBServerRequest *)serverRequest fileName:(NSString *)fileName;
-(BOOL)addWithRootCA:(NSString *)caDerFilePath strictHostNameCheck:(BOOL)check;

+(BOOL)shouldLog;
@end
