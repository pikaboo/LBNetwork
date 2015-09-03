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
//  LBServerRequest.m
//  LBNetwork
//
//  Created by Lena Brusilovski on 09/1/15.
//  Copyright (c) 2015 LenaBrusilovski. All rights reserved.
//

#import "LBNetwork.h"
#import <UIKit/UIKit.h>
@interface LBServerRequest ()

@end

@implementation LBServerRequest

+(instancetype)request{
    return [[[self class]alloc]init];
}

+(instancetype)getRequest{
    LBServerRequest *request = [self request];
    request.method = kMethodGET;
    return request;
}

+(instancetype)postRequest{
    LBServerRequest *request = [self request];
    request.method = kMethodPOST;
    return request;
}

+(instancetype)uploadRequest:(NSData *)data{
    LBServerRequest *request = [self postRequest];
    request.requestBodyData = data;
    return request;
}

+(instancetype)imageUploadRequest:(UIImage *)image{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    return [self uploadRequest:imageData];
}
-(NSURL *)requestURL{
    return [NSURL URLWithString:self.path];
}

-(instancetype)copy{
    LBServerRequest *copy = [[LBServerRequest alloc]init];
    copy.path = [self.path copy];
    copy.responseHandler = [self.responseHandler copy];
    copy.headers = [self.headers copy];
    copy.requestBodyString = [self.requestBodyString copy];
    copy.requestBodyData = [self.requestBodyData copy];
    copy.httpRequest = [self.httpRequest mutableCopy];
    return copy;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return [self copy];
}
-(instancetype)mutableCopy{
    return [self copy];
}

-(void)cleanUp{
    self.responseHandler = nil;
}
@end