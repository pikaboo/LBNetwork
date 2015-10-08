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
//  LBServerResponse.m
//  LBNetwork
//
//  Created by Lena Brusilovski on 1/12/14.
//

#import "LBServerResponse.h"

@implementation LBServerResponse


+ (instancetype)handleServerResponse:(LBURLConnection *)connection
                        deserializer:(id<LBDeserializer>)deserializer
                            error:(NSError *)error{
    NSHTTPURLResponse *response = connection.rawResponse;
    NSString* responseString = [[connection data] toString];
    LBServerResponse *res = [[self alloc] init];
    [res setHeaders:[response allHeaderFields]];
    [res setStatusCode:[response statusCode]];
    [res setRawResponse:responseString];
    [res setError:error];
    if(deserializer){
        res.output = [deserializer deserialize:[connection data] toClass:[connection.request responseClass]];
    }
    return res;
}



- (void)setRawResponse:(NSString *)rawResponse {
    rawResponse =
    [rawResponse stringByReplacingOccurrencesOfString:@"{\"d\":null}"
                                           withString:@""];
    _rawResponseData = [rawResponse dataUsingEncoding:NSUTF8StringEncoding];
    _rawResponseString = rawResponse;
    if ([rawResponse length] == 0) {
        return;
    }
}
- (NSString *)description {
    return [NSString stringWithFormat:@"ServerResponse headers: "
            "%@\ncookie:%@\nrawResponse:%@"
            "\nstatusCode=%ld,output=%@",
            _headers, _cookie, _rawResponseString,
            (long)_statusCode, _output];
}

- (void)setHeaders:(NSDictionary *)headers {
    _headers = headers;
    _cookie = [_headers valueForKey:@"Set-Cookie"]; 
}


@end

@implementation NSData (LBServerResponse)

-(NSString *)toString{
   return[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

@end
