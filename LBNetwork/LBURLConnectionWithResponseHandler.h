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
//  LBURLConnectionWithResponseHandler.h
//  LBNetwork
//
//  Created by Lena Brusilovski on 3/16/14.

@class LBServerResponse;


@interface LBURLConnectionWithResponseHandler : NSURLConnection
typedef void (^LBServerResponseHandler)(LBServerResponse *response);

@property (nonatomic,strong) LBServerResponseHandler responseHandler;
@property (nonatomic,strong) NSHTTPURLResponse *rawResponse;
@property (nonatomic,strong) NSMutableData *data;
@property (nonatomic,assign) NSInteger retries;
@property (nonatomic,strong) NSMutableString *retryCount;
@property (nonatomic,strong) NSString *requestBody;



@end
