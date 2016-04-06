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
//  LBHTTPSClient.m
//  LBNetwork
//
//  Created by Lena Brusilovski on 3/13/14.
//

#import "LBNetwork.h"

NSString *const kMethodGET = @"GET";
NSString *const kMethodPOST = @"POST";
NSString *const kMethodPUT = @"PUT";
NSString *const kMethodDELETE = @"DELETE";

NSString *const ContentTypeAutomatic = @"jsonmodel/automatic";
NSString *const ContentTypeJSON = @"application/json";
NSString *const ContentTypeJSONUTF8 = @"application/json; charset=UTF-8";
NSString *const ContentTypeWWWEncoded = @"application/x-www-form-urlencoded";
NSString *const ContentTypeApplicationJavaScript = @"application/javascript";

NSString *const DataContentTypeImage = @"image/jpeg";
NSString *const DataContentTypeFile = @"application/octet-stream";

#define LBShowLog [LBHTTPSClient shouldLog]
#define LBLogDebug(fmt, ...) if (LBShowLog) LogDebug(fmt,##__VA_ARGS__)
#define LBLogInfo(fmt, ...)  if (LBShowLog) LogInfo(fmt,##__VA_ARGS__)
#define LBLogError(fmt, ...) if (LBShowLog) LogError(fmt,##__VA_ARGS__)

@interface LBHTTPSClient ()
@property (nonatomic, strong) UIAlertView *alert;
@property (nonatomic, strong) NSOperationQueue *connectionQueue;
@end

@implementation LBHTTPSClient {
    CFArrayRef caChainArrayRef;
    BOOL checkHostname;
}

static id sharedClient;

+ (instancetype)sharedClient {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

- (id)init {
    if (self = [super init]) {
        /**
         * Defaults for HTTP requests
         */
        _defaultTextEncoding = NSUTF8StringEncoding;
        _defaultCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

        /**
         * Whether the iPhone net indicator automatically shows when making requests
         */
        _doesControlIndicator = YES;

        /**
         * Default request content type
         */
        _requestContentType = ContentTypeAutomatic;
        self.connectionProperties = [[LBURLConnectionProperties alloc] init];
        self.connectionProperties.maxRetryCount = 3;
        self.connectionProperties.logLevel = LogLevelDebug;
        self.connectionQueue = [[NSOperationQueue alloc] init];
        self.connectionQueue.name = @"LBNetworkQueue";
    }
    return self;
}

+ (NSString *)contentTypeForRequestString:(NSString *)requestString {
    //fetch the charset name from the default string encoding
    NSString *contentType = ContentTypeAutomatic; //requestContentType;

    if (requestString.length > 0 && [contentType isEqualToString:ContentTypeAutomatic]) {
        //check for "eventual" JSON array or dictionary
        NSString *firstAndLastChar = [NSString stringWithFormat:@"%@%@",
                                                                [requestString substringToIndex:1],
                                                                [requestString substringFromIndex:requestString.length - 1]];

        if ([firstAndLastChar isEqualToString:@"{}"] || [firstAndLastChar isEqualToString:@"[]"]) {
            //guessing for a JSON request
            contentType = ContentTypeJSON;
        }
        else {
            //fallback to www form encoded params
            contentType = ContentTypeWWWEncoded;
        }
    }

    //type is set, just add charset
    NSString *charset = (NSString *) CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return [NSString stringWithFormat:@"%@; charset=%@", contentType, charset];
}

#pragma mark - request with authentication challenge

- (void)asyncRequestDataForServerRequest:(LBServerRequest *)serverRequest {

    [self setupRequest:serverRequest];

    //fire the request
    [self startRequest:serverRequest];
}

- (LBServerRequest *)setupRequest:(LBServerRequest *)serverRequest {
    NSMutableURLRequest *httpRequest = [[NSMutableURLRequest alloc] initWithURL:serverRequest.requestURL
                                                                    cachePolicy:_defaultCachePolicy
                                                                timeoutInterval:serverRequest.requestTimeoutSeconds];
    [httpRequest setHTTPMethod:serverRequest.method];

    if ([_requestContentType isEqualToString:ContentTypeAutomatic]) {
        //automatic content type
        if (serverRequest.requestBodyData) {
            NSString *bodyString = [[NSString alloc] initWithData:serverRequest.requestBodyData
                                                         encoding:NSUTF8StringEncoding];
            [httpRequest setValue:[LBHTTPSClient contentTypeForRequestString:bodyString]
               forHTTPHeaderField:@"Content-type"];
        }
    }
    else {
        //user set content type
        [httpRequest setValue:_requestContentType forHTTPHeaderField:@"Content-type"];
    }


    //add the custom headers
    for (NSString *key in [serverRequest.headers allKeys]) {
        [httpRequest setValue:serverRequest.headers[key] forHTTPHeaderField:key];
    }
    for (NSString *key in [serverRequest.basicAuthHeaders allKeys]) {
        [httpRequest setValue:serverRequest.basicAuthHeaders[key] forHTTPHeaderField:key];
    }
    
    if (serverRequest.requestBodyData && ![serverRequest.method isEqualToString:kMethodGET]) {
        [httpRequest setHTTPBody:serverRequest.requestBodyData];
        [httpRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long) serverRequest.requestBodyData.length] forHTTPHeaderField:@"Content-Length"];
    }

    if ([serverRequest.method isEqualToString:kMethodGET]) {
        NSMutableArray *pathWithParams = [[NSMutableArray alloc] init];
        NSMutableString *path = [serverRequest.path mutableCopy];

        for (NSString *key in [serverRequest.params allKeys]) {
            NSString *param = [NSString stringWithFormat:@"%@=%@", key, [serverRequest.params objectForKey:key]];
            [pathWithParams addObject:param];
            LBLogDebug(@"added param:%@", param);
        }

        if (pathWithParams.count) {
            if (![path hasSuffix:@"?"]) {
                [path appendString:@"?"];
                LBLogDebug(@"added '?'");
            }
            [path appendFormat:@"%@", [pathWithParams componentsJoinedByString:@"&"]];
        }
        [httpRequest setURL:[NSURL URLWithString:path]];
        LBLogDebug(@"path with params:%@", [[httpRequest URL] absoluteString]);
    }

    serverRequest.httpRequest = httpRequest;

    return serverRequest;
}

- (void)startSynchronousRequest:(LBServerRequest *)request responseHandler:(LBServerResponseHandler)responseHandler {

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    request = [self setupRequest:request];
    NSData *result = [LBURLConnection sendSynchronousRequest:request.httpRequest returningResponse:&response error:&error];
    request.responseHandler = responseHandler;
    id <LBDeserializer> deserializer = [self.connectionProperties deserializerForContentType:[LBURLConnection responseContentType:response]];
    [self handleResponse:[LBServerResponse handleServerResponse:response request:request data:result deserializer:deserializer error:error]];
}

- (void)startRequest:(LBServerRequest *)request {
    LBURLConnection *con = [[LBURLConnection alloc] initWithRequest:request delegate:self];
    con.retries = 1;
    if ([[self.connectionProperties errorHandler] shouldDisplayActivityIndicatorForRequest:[con originalRequest]]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    [con setDelegateQueue:self.connectionQueue];
    [con start];
    LBLogDebug(@"started connection");
}

- (void)asyncUploadRequestRawData:(LBServerRequest *)serverRequest {
    NSMutableURLRequest *httpRequest = [[NSMutableURLRequest alloc] initWithURL:serverRequest.requestURL];
    [httpRequest setCachePolicy:_defaultCachePolicy];
    [httpRequest setHTTPShouldHandleCookies:NO];
    [httpRequest setTimeoutInterval:serverRequest.requestTimeoutSeconds];
    [httpRequest setHTTPMethod:kMethodPOST];

    for (NSString *key in [serverRequest.headers allKeys]) {
        [httpRequest setValue:serverRequest.headers[key] forHTTPHeaderField:key];
    }

    [httpRequest setHTTPBody:serverRequest.requestBodyData];

    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long) [serverRequest.requestBodyData length]];
    [httpRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];

    serverRequest.httpRequest = httpRequest;
    [self startRequest:serverRequest];
}

- (void)asyncUploadRequestData:(LBServerRequest *)serverRequest fileName:(NSString *)fileName {
    NSMutableURLRequest *httpRequest = [[NSMutableURLRequest alloc] initWithURL:serverRequest.requestURL];
    [httpRequest setCachePolicy:_defaultCachePolicy];
    [httpRequest setHTTPShouldHandleCookies:NO];
    [httpRequest setTimeoutInterval:serverRequest.requestTimeoutSeconds];
    [httpRequest setHTTPMethod:kMethodPOST];

    for (NSString *key in [serverRequest.headers allKeys]) {
        [httpRequest setValue:serverRequest.headers[key] forHTTPHeaderField:key];
    }

    NSString *boundary = @"lb_network_boundary_multipart_request";

    // set Content-Type in HTTP header
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [httpRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];

    // post body
    NSMutableData *body = [NSMutableData data];

    // add params (all params are strings)
    for (NSString *key in [serverRequest.params allKeys]) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", [serverRequest.params objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    // add image data
    if (serverRequest.requestBodyData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@; filename=%@\r\n", @"file", fileName] dataUsingEncoding:NSUTF8StringEncoding]];

        [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", serverRequest.dataContentType] dataUsingEncoding:NSUTF8StringEncoding]];

        LBLogInfo(@"requestBody:%@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
        [body appendData:serverRequest.requestBodyData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    // setting the body of the post to the reqeust
    [httpRequest setHTTPBody:body];

    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long) [body length]];
    [httpRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];

    serverRequest.httpRequest = httpRequest;
    [self startRequest:serverRequest];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    LBLogDebug(@"Response recieved from url:%@", [[[connection originalRequest] URL] description]);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    LBURLConnection *con = (LBURLConnection *) connection;
    [con setRawResponse:httpResponse];
    con.data = [[NSMutableData alloc] initWithLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    LBURLConnection *con = (LBURLConnection *) connection;
    [[con data] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    LBURLConnection *con = (LBURLConnection *) connection;
    NSData *data = [con data];
    NSString *stringData = [data toString];
    if (stringData.length > 1000) {
        LBLogDebug(@"Data received:%@", @(stringData.length));
    }
    else {
        LBLogDebug(@"Data recieved:%@", stringData);
    }
    id <LBDeserializer> deserializer = [self.connectionProperties deserializerForContentType:[con responseContentType]];
    LBServerResponse *response = [LBServerResponse handleServerResponse:con.rawResponse request:con.request data:con.data deserializer:deserializer error:nil];

//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self handleResponse:response];
        [self cleanUp:con];
//    }];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSHTTPURLResponse *)redirectResponse {
    LBURLConnection *con = (LBURLConnection *)connection;
    if (con.request.shouldAutoRedirect || !redirectResponse ) {
        return request;
    }
    
    con.rawResponse = redirectResponse;
    return nil;
    
}

- (void)handleResponse:(LBServerResponse *)response {
    if (!response.request.responseHandler) {
        LBResponseType type = LBResonseTypeSuccess;
        if ([self.connectionProperties.responseTypeResolver respondsToSelector:@selector(responseType:)]) {
            type = [self.connectionProperties.responseTypeResolver responseType:response];
        }
        LBLogDebug(@"onMainThread? %lu", (long) [NSThread isMainThread]);
        switch (type) {

            case LBResponseTypeFail: {
                if (response.request.failResponseHandler) {
                    response.request.failResponseHandler(response.error);
                }
            }
                break;
            case LBResonseTypeSuccess: {
                if (response.request.successResponseHandler) {
                    response.request.successResponseHandler(response.output);
                }
            }
                break;
            default:
                break;
        }
    }
    else {
        response.request.responseHandler(response);
    }
    [self handleErrorIfNeeded:response];
}


- (void)cleanUp:(LBURLConnection *)con {

    [con cancel];
    [con.request cleanUp];
    [con.data setLength:0];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {

    BOOL trust = [[protectionSpace authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust];
    return trust;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef trust = nil;
        SecTrustResultType result = 0;
        OSStatus err = errSecSuccess;

        //#if DEBUG
        //        {
        //            NSLog(@"Chain received from the server (working 'up'):");
        //            CFIndex certificateCount = SecTrustGetCertificateCount(challenge.protectionSpace.serverTrust);
        //            for(int i = 0; i < certificateCount; i++) {
        //                SecCertificateRef certRef = SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, i);
        //                //                CFStringRef str = SecCertificateCopyLongDescription(NULL, certRef, nil);
        //                //                NSLog(@"   %02i: %@", 1+i, str);
        //                //                CFRelease(str);
        //            }
        //
        //            NSLog(@"Local Roots we trust:");
        //            for(int i = 0; i < CFArrayGetCount(caChainArrayRef); i++) {
        //                SecCertificateRef certRef = (SecCertificateRef) CFArrayGetValueAtIndex(caChainArrayRef, i);
        //                //                CFStringRef str = SecCertificateCopyLongDescription(NULL, certRef, nil);
        //                //                NSLog(@"   %02i: %@", 1+i, str);
        //                //                CFRelease(str);
        //            }
        //        }
        //#endif

        if (checkHostname) {
            // We use the standard Policy of SSL - which also checks hostnames.
            // -- see SecPolicyCreateSSL() for details.
            //
            trust = challenge.protectionSpace.serverTrust;
            //
#if DEBUG
            LBLogDebug(@"The certificate is expected to match '%@' as the hostname",
                       challenge.protectionSpace.host);
#endif
        }
        else {
            // Create a new Policy - which goes easy on the hostname.
            //

            // Extract the chain of certificates provided by the server.
            //
            CFIndex certificateCount = SecTrustGetCertificateCount(challenge.protectionSpace.serverTrust);
            NSMutableArray *chain = [NSMutableArray array];

            for (int i = 0; i < certificateCount; i++) {
                SecCertificateRef certRef = SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, i);
                [chain addObject:(__bridge id) (certRef)];
            }

            // And create a bland policy which only checks signature paths.
            //
            if (err == errSecSuccess)
                err = SecTrustCreateWithCertificates((__bridge CFArrayRef) (chain),
                        SecPolicyCreateBasicX509(), &trust);
#if DEBUG
            LBLogDebug(@"The certificate is NOT expected to match the hostname '%@' ",
                       challenge.protectionSpace.host);
#endif
        }

        if (self.certificateFromAuthority) {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:trust]
                 forAuthenticationChallenge:challenge];
            return;
        }
        else {

            // Explicity specify the list of certificates we actually trust (i.e. those I have hardcoded
            // in the app - rather than those provided by some randon server on the internet).
            //
            if (err == errSecSuccess)
                err = SecTrustSetAnchorCertificates(trust, caChainArrayRef);

            // And only use above - i.e. do not check the system its global keychain or something
            // else the user may have fiddled with.
            //
            if (err == errSecSuccess)
                err = SecTrustSetAnchorCertificatesOnly(trust, YES);

            if (err == errSecSuccess)
                err = SecTrustEvaluate(trust, &result);

            if (err == errSecSuccess) {
                switch (result) {
                    case kSecTrustResultProceed:
                        // User gave explicit permission to trust this specific
                        // root at some point (in the past).
                        //
                        LBLogDebug(@"GOOD. kSecTrustResultProceed - the user explicitly trusts this CA");
                        [challenge.sender useCredential:[NSURLCredential credentialForTrust:trust]
                             forAuthenticationChallenge:challenge];
                        goto done;
                        break;
                    case kSecTrustResultUnspecified:
                        // The chain is technically valid and matches up to the root
                        // we provided. The user has not had any say in this though,
                        // hence it is not a kSecTrustResultProceed.
                        //
                        LBLogDebug(@"GOOD. kSecTrustResultUnspecified - So things are technically trusted. But the user was not involved.");
                        [challenge.sender useCredential:[NSURLCredential credentialForTrust:trust]
                             forAuthenticationChallenge:challenge];
                        goto done;
                        break;
                    case kSecTrustResultInvalid:
                        LBLogDebug(@"FAIL. kSecTrustResultInvalid");
                        break;
                    case kSecTrustResultDeny:
                        LBLogDebug(@"FAIL. kSecTrustResultDeny (i.e. user said no explicitly)");
                        break;
                    case kSecTrustResultFatalTrustFailure:
                        LBLogDebug(@"FAIL. kSecTrustResultFatalTrustFailure");
                        break;
                    case kSecTrustResultOtherError:
                        LBLogDebug(@"FAIL. kSecTrustResultOtherError");
                        break;
                    case kSecTrustResultRecoverableTrustFailure:
                        LBLogDebug(@"FAIL. kSecTrustResultRecoverableTrustFailure (i.e. user could say OK, but has not been asked this)");
                        break;
                    default:
                        NSAssert(NO, @"Unexpected result: %d", result);
                        break;
                }
                // Reject.
                [challenge.sender cancelAuthenticationChallenge:challenge];
                goto done;
            };
            //        CFStringRef str =SecCopyErrorMessageString(err,NULL);
            //        NSLog(@"Internal failure to validate: result %@", str);
            //        CFRelease(str);

            [[challenge sender] cancelAuthenticationChallenge:challenge];

            done:
            if (!checkHostname)
                CFRelease(trust);
            return;
        }
    }
    // In this example we can cancel at this point - as we only do
    // canAuthenticateAgainstProtectionSpace against ServerTrust.
    //
    // But in other situations a more gentle continue may be appropriate.
    //
    // [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];

    LBLogDebug(@"Not something we can handle - so we're canceling it.");
    [challenge.sender cancelAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    __block LBURLConnection *con = (LBURLConnection *) connection;
    LBLogDebug(@"%@", [NSString stringWithFormat:@"Did recieve error: %@", [error description]]);
    LBLogDebug(@"%@", [NSString stringWithFormat:@"%@", [[error userInfo] description]]);
    LBLogDebug(@"response:%@", con.rawResponse);
    LBLogDebug(@"statusCode:%@", @(con.rawResponse.statusCode));

    BOOL shouldRetryRequest = NO;
    if ([[self.connectionProperties errorHandler] respondsToSelector:@selector(shouldRetryRequest:forCurrentTry:)]) {
        shouldRetryRequest = [[self.connectionProperties errorHandler] shouldRetryRequest:error forCurrentTry:con.retries];
    }

    if (shouldRetryRequest) {
        LBURLConnection *conrestart = [con copy];
        conrestart.retries = con.retries + 1;
        [conrestart setDelegateQueue:self.connectionQueue];
        [conrestart start];
        [con cancel];
    }
    else {
        LBServerResponse *response = [LBServerResponse handleServerResponse:con.rawResponse
                                                                    request:con.request
                                                                       data:con.data
                                                               deserializer:nil
                                                                      error:error];
        response.currentRequestTryCount = con.retries;
        response.error = error;
        if (con.request.failResponseHandler) {
            LBURLConnection *lburlConnection = con;
            LBServerRequest *request = lburlConnection.request;
            LBServerFailResponseHandler pFunction = request.failResponseHandler;
            LBServerResponse *serverResponse = response;
            NSError *error1 = serverResponse.error;
            pFunction(error1);
        }
        else {
            if (con.request.responseHandler) {
                con.request.responseHandler(response);
            }
        }
        [con.request cleanUp];
        [con.data setLength:0];
        [con cancel];
        con = nil;

        [self handleErrorIfNeeded:response];
    }
}

- (void)handleErrorIfNeeded:(LBServerResponse *)response {
    BOOL shouldDisplayErrorForResponse = NO;
    if ([[self.connectionProperties errorHandler] respondsToSelector:@selector(shouldDisplayErrorForResponse:)]) {
        shouldDisplayErrorForResponse = [[self.connectionProperties errorHandler] shouldDisplayErrorForResponse:response];
    }
    if (shouldDisplayErrorForResponse) {
        NSString *title, *message, *okButton;
        if ([[self.connectionProperties errorHandler] respondsToSelector:@selector(titleForErrorForResponse:)]) {
            title = [[self.connectionProperties errorHandler] titleForErrorForResponse:response];
        }
        if ([[self.connectionProperties errorHandler] respondsToSelector:@selector(messageForErrorForResponse:)]) {
            message = [[self.connectionProperties errorHandler] messageForErrorForResponse:response];
        }
        if ([[self.connectionProperties errorHandler] respondsToSelector:@selector(titleForOKButtonErrorMessageForResponse:)]) {
            okButton = [[self.connectionProperties errorHandler] titleForOKButtonErrorMessageForResponse:response];
        }
        if (!title && !message && !okButton) {
            return;
        }
        if (!self.alert || ![[self.alert buttonTitleAtIndex:0] isEqualToString:okButton]) {
            self.alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:okButton otherButtonTitles:nil];
        }
        if (![self.alert isVisible]) {
            [self.alert setTitle:title];
            [self.alert setMessage:message];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.alert show];
            });
        }
    }
}

- (void)sendRequest:(LBServerRequest *)request {

    LBLogInfo(@"sending %@ request to path:%@", request.method, request.path);
    LBLogDebug(@"withParams:%@, andBody:%@, andHeaders:%@,handingResponse:%d", request.params, request.requestBodyString, request.headers, (request.successResponseHandler != nil));

    [self asyncRequestDataForServerRequest:request];
}

- (BOOL)addWithRootCA:(NSString *)caDerFilePath strictHostNameCheck:(BOOL)check {
    checkHostname = check;
    NSData *derCA = [NSData dataWithContentsOfFile:caDerFilePath];
    if (!derCA) {
        return NO;
    }

    SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) derCA);
    if (!caRef) {
        return NO;
    }
    NSArray *chain = [NSArray arrayWithObject:(__bridge id) (caRef)];

    return [self initWithRootCAs:chain strictHostNameCheck:check];
}

- (BOOL)initWithRootCAs:(NSArray *)anArrayOfSecCertificateRef strictHostNameCheck:(BOOL)check {

    caChainArrayRef = CFBridgingRetain(anArrayOfSecCertificateRef);

    return YES;
}

- (void)dealloc {
    if (caChainArrayRef)
        CFRelease(caChainArrayRef);
}

+ (BOOL)shouldLog {
    return [[[LBHTTPSClient sharedClient] connectionProperties] logLevel] == LogLevelDebug;
}

- (void)responseType:(id)sender {
}
@end
