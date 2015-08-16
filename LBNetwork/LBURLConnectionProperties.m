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

@interface LBURLConnectionProperties()<LBConnectionErrorHandler>
@end

@implementation LBURLConnectionProperties

-(id)init{
    self = [super init];
    if(self) {
        self.errorHandler = self;
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
    return  response.statusCode>kHTTPStatusCodeBadRequest;
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



@end
