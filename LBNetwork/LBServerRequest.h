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
//  LBServerRequest.h
//  LBNetwork
//
//  Created by Lena Brusilovski on 09/1/15.
//  Copyright (c) 2015 LenaBrusilovski. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIImage;
@class LBServerResponse;
@interface LBServerRequest : NSObject <NSCopying>
typedef void (^LBServerResponseHandler)(LBServerResponse *response);

@property (nonatomic,strong)NSDictionary *headers;
@property (nonatomic,strong)NSDictionary *params;
@property (nonatomic,copy)NSString *requestBodyString;
@property (nonatomic,strong)NSData *requestBodyData;
@property (nonatomic,strong)NSString *path;
@property (nonatomic,strong)NSString *method;
@property (nonatomic,strong)NSString *dataContentType;
@property (nonatomic,assign)Class responseClass;
@property (nonatomic,strong)LBServerResponseHandler responseHandler;
@property (nonatomic,strong)NSMutableURLRequest *httpRequest;

+(instancetype)request;
+(instancetype)getRequest;
+(instancetype)postRequest;
+(instancetype)uploadRequest:(NSData *)data;
+(instancetype)imageUploadRequest:(UIImage *)image;
-(NSURL *)requestURL;
-(void)cleanUp;
@end
