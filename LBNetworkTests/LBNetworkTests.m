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
//  LBNetworkTests.m
//  LBNetworkTests
//
//  Created by Lena Brusilovski on 8/18/14.
//
#import "LBNetwork.h"
#import <XCTest/XCTest.h>

@interface LBNetworkTests : XCTestCase<NSURLConnectionDataDelegate>

@end

@implementation LBNetworkTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



-(void)testCopy{
  
    LBServerRequest *request = [self createRequest];
    LBServerRequest *requestCopy = [request copy];
    
    NSString *orig =[NSString stringWithFormat:@"%p",request];
    NSString *copy = [NSString stringWithFormat:@"%p",requestCopy];
    XCTAssertNotEqual(orig,copy,@"they should not have the same memory address");
    XCTAssertNotNil(requestCopy.responseHandler,@"response handler  should not be null");
    XCTAssertNotNil(requestCopy.httpRequest);
    XCTAssertEqual(requestCopy.httpRequest.URL, request.httpRequest.URL,@"urls should be equal");
    XCTAssertNil(requestCopy.converter,@"converter should not be null");
}

-(LBServerRequest *)createRequest{
    LBServerRequest *request = [[LBServerRequest alloc]init];
    request.path = @"www.google.com";
    request.httpRequest = [[NSMutableURLRequest alloc]initWithURL:request.requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    [request.httpRequest setHTTPMethod:kMethodGET];
    XCTAssertNotNil(request.httpRequest.URL,@"url should not be null");
    request.headers = @{@"LenaHeaderKEY":@"LenaHeaderValue"};
    request.method = kMethodGET;
    request.responseHandler = ^(LBServerResponse *response){
        NSLog(@"stam");
    };
    request.requestBodyString = @"Lalala";
    return request;
}

-(void)testCopyConnection{
    LBServerRequest *request = [self createRequest];
    LBURLConnection *connection = [[LBURLConnection alloc]initWithRequest:request delegate:self];
    connection.retries = 5;
    LBURLConnection *connectionCopy = [connection copy];
    NSString *orig =[NSString stringWithFormat:@"%p",connection];
    NSString *copy = [NSString stringWithFormat:@"%p",connectionCopy];
    XCTAssertNotEqual(orig,copy,@"they should not have the same memory address");
    
}

-(void)testCreateConnection{
    LBServerRequest *request = [self createRequest];
    LBURLConnection *con = [[LBURLConnection alloc]initWithRequest:request delegate:self];
    XCTAssertNotNil(con.request,@"request should not be null");
}
@end
