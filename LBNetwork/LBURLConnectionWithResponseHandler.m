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
//  LBURLConnectionWithResponseHandler.m
//  LBNetwork
//
//  Created by Lena Brusilovski on 3/16/14.
//


#import "LBNetwork.h"

@implementation LBURLConnectionWithResponseHandler


-(id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate{
    self = [super initWithRequest:request delegate:delegate startImmediately:NO];
    if(self){
        self.retries = 0;
        self.retryCount = [[NSMutableString alloc]init];
    }
    return self;
}


-(void)setResponseHandler:(LBServerResponseHandler)responseHandler{
    _responseHandler = responseHandler;
    if(!responseHandler){
        if([LBHTTPSClient shouldLog]){
        LogInfo(@"set nill response handler");
        }
    }
}
@end
