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
//  LBURLConnection.m
//  LBNetwork
//
//  Created by Lena Brusilovski on 3/16/14.
//


#import "LBNetwork.h"
@interface LBURLConnection ()
@property(nonatomic,assign)id connectionDelegate;
@end
@implementation LBURLConnection


-(instancetype)initWithRequest:(LBServerRequest*)request delegate:(id)delegate {
	self = [super initWithRequest:request.httpRequest delegate:delegate startImmediately:NO];

	if(self){
        self.request = request;
        self.connectionDelegate = delegate;
		self.retries = 0;
		self.retryCount = [[NSMutableString alloc]init];

		if(!request.successResponseHandler){
			if([LBHTTPSClient shouldLog]){
				LogInfo(@"set nill response handler");
			}
		}
	}
	return self;
}

-(instancetype)initWithRequest:(LBServerRequest*)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
	self = [self initWithRequest:request delegate:delegate];

	if(self){
		if(startImmediately){
			[self start];
		}
	}
	return self;
}

-(NSString *)responseContentType{
    return [[self.rawResponse allHeaderFields]objectForKey:@"Content-Type"];
}

-(instancetype)copy {
    LBURLConnection *copy = [[LBURLConnection alloc]initWithRequest:self.request delegate:self.connectionDelegate];
	copy.retries = self.retries;
	copy.retryCount = self.retryCount;
    copy.data = [self.data copy];
    return  copy;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return [self copy];
}

-(instancetype)mutableCopy {
	return [self copy];
}


@end
