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

NSString* const kMethodGET = @"GET";
NSString* const kMethodPOST = @"POST";
NSString* const kMethodPUT = @"PUT";
NSString* const kMethodDELETE = @"DELETE";

NSString* const ContentTypeAutomatic = @"jsonmodel/automatic";
NSString* const ContentTypeJSON = @"application/json;charset=UTF-8";
NSString* const ContentTypeWWWEncoded = @"application/x-www-form-urlencoded";

NSString* const DataContentTypeImage = @"image/jpeg";
NSString* const DataContentTypeVideo = @"application/octet-stream";

#define LBShowLog [LBHTTPSClient shouldLog]
#define LBLogDebug(fmt,...) if (LBShowLog) LogDebug(fmt,##__VA_ARGS__)
#define LBLogInfo(fmt,...)  if (LBShowLog) LogInfo(fmt,##__VA_ARGS__)
#define LBLogError(fmt,...) if (LBShowLog) LogError(fmt,##__VA_ARGS__)
@interface LBHTTPSClient ()
@property(nonatomic, strong) UIAlertView* alert;
@end
@implementation LBHTTPSClient {
    CFArrayRef caChainArrayRef;
    BOOL checkHostname;
}

static LBHTTPSClient* sharedClient;

+ (instancetype)sharedClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc]init];
    });
    return sharedClient;
}

- (id)init
{
    if (self = [super init]) {
        /**
         * Defaults for HTTP requests
         */
        _defaultTextEncoding = NSUTF8StringEncoding;
        _defaultCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        _defaultTimeoutInSeconds = 60;
        
        /**
         * Whether the iPhone net indicator automatically shows when making requests
         */
        _doesControlIndicator = YES;
        
        /**
         * Default request content type
         */
        _requestContentType = ContentTypeAutomatic;
        self.connectionProperties = [[LBURLConnectionProperties alloc]init];
        self.connectionProperties.maxRetryCount = 3;
        self.connectionProperties.logLevel = LogLevelDebug;
    }
    return self;
}

+ (NSString*)contentTypeForRequestString:(NSString*)requestString
{
    //fetch the charset name from the default string encoding
    NSString* contentType = ContentTypeAutomatic; //requestContentType;
    
    if (requestString.length > 0 && [contentType isEqualToString:ContentTypeAutomatic]) {
        //check for "eventual" JSON array or dictionary
        NSString* firstAndLastChar = [NSString stringWithFormat:@"%@%@",
                                      [requestString substringToIndex:1],
                                      [requestString substringFromIndex:requestString.length - 1]];
        
        if ([firstAndLastChar isEqualToString:@"{}"] || [firstAndLastChar isEqualToString:@"[]"]) {
            //guessing for a JSON request
            contentType = ContentTypeJSON;
        } else {
            //fallback to www form encoded params
            contentType = ContentTypeWWWEncoded;
        }
    }
    
    //type is set, just add charset
    NSString* charset = (NSString*)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return [NSString stringWithFormat:@"%@; charset=%@", contentType, charset];
}

#pragma mark - request with authentication challenge

- (void)asyncRequestDataFromURL:(NSURL*)url method:(NSString*)method parameters:(NSDictionary *)params bodyString:(NSString*)bodyString requestBody:(NSData*)bodyData headers:(NSDictionary*)headers andServerResponseHandler:(LBServerResponseHandler)serverResponseHandler
{
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:_defaultCachePolicy
                                                            timeoutInterval:_defaultTimeoutInSeconds];
    [request setHTTPMethod:method];
    
    if ([_requestContentType isEqualToString:ContentTypeAutomatic]) {
        //automatic content type
        if (bodyData) {
            NSString* bodyString = [[NSString alloc] initWithData:bodyData
                                                         encoding:NSUTF8StringEncoding];
            [request setValue:[LBHTTPSClient contentTypeForRequestString:bodyString]
           forHTTPHeaderField:@"Content-type"];
        }
    } else {
        //user set content type
        [request setValue:_requestContentType
       forHTTPHeaderField:@"Content-type"];
    }
    
    //    //add all the custom headers defined
    //    for (NSString* key in [requestHeaders allKeys]) {
    //        [request setValue:requestHeaders[key] forHTTPHeaderField:key];
    //    }
    
    //add the custom headers
    for (NSString* key in [headers allKeys]) {
        [request setValue:headers[key]
       forHTTPHeaderField:key];
    }
    
    if (bodyData && ![method isEqualToString:kMethodGET]) {
        [request setHTTPBody:bodyData];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)bodyData.length]
       forHTTPHeaderField:@"Content-Length"];
    }

    NSMutableString *pathWithParams = nil;
    if ([method isEqualToString:kMethodGET]) {
        pathWithParams = [[NSMutableString alloc]init];
        NSString *path = [url absoluteString];
       
        if (![path hasSuffix:@"?"]) {
            [pathWithParams appendString:@"?"];
                LBLogDebug(@"added ?");
        }

        for (NSString *key in [params allKeys]) {
            NSString *param = [NSString stringWithFormat:@"%@=%@",key,[params objectForKey:key]];
            [pathWithParams appendFormat:@"%@&",param];
                LBLogDebug(@"added param:%@",param);
            [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",path,pathWithParams]]];
        }
            LBLogDebug(@"path with params:%@",[[request URL]absoluteString]);

    }



    //fire the request
    [self startRequest:request body:bodyString andServerResponseHandler:serverResponseHandler];
}

-(void)startRequest:(NSMutableURLRequest *)request body:(NSString *)body andServerResponseHandler:(LBServerResponseHandler)serverResponseHandler{
    LBURLConnectionWithResponseHandler* con = [[LBURLConnectionWithResponseHandler alloc] initWithRequest:request
                                                                                                 delegate:self];
    con.responseHandler = serverResponseHandler;
    con.requestBody = [body copy];
    con.retries = 1;
    if ([[self.connectionProperties errorHandler] shouldDisplayActivityIndicatorForRequest:[con originalRequest]]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    [con start];
}

-(void)asyncUploadData:(NSData *)data contentType:(NSString *)dataContentType toPath:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters fileName:(NSString *)fileName responseHandler:(LBServerResponseHandler)serverResponseHandler{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:path]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:60];
    [request setHTTPMethod:kMethodPOST];
    
    for (NSString* key in [headers allKeys]) {
        [request setValue:headers[key]
       forHTTPHeaderField:key];
    }
    
    NSString *boundary = @"lb_network_boundary_multipart_request";
    
    // set Content-Type in HTTP header
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // post body
    NSMutableData *body = [NSMutableData data];
    
    // add params (all params are strings)
    for(NSString *key in [parameters allKeys]){
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", [parameters objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    // add image data
    if (data) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@; filename=%@\r\n", @"file",fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n",dataContentType] dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        if([[self class]shouldLog]){
            LogInfo(@"requestBody:%@",[[NSString alloc]initWithData:body encoding:NSUTF8StringEncoding]);
        }
        [body appendData:data];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    
    [self startRequest:request body:nil andServerResponseHandler:serverResponseHandler];
}

-(void)asyncImageUpload:(UIImage *)image toPath:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters fileName:(NSString *)fileName responseHandler:(LBServerResponseHandler)serverResponseHandler{
    
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [self asyncUploadData:imageData contentType:DataContentTypeImage toPath:path headers:headers parameters:parameters fileName:fileName responseHandler:serverResponseHandler];
    
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    if([LBHTTPSClient shouldLog]){
    LogDebug(@"Response recieved from url:%@", [[[connection originalRequest] URL] description]);
    }
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    LBURLConnectionWithResponseHandler* con = (LBURLConnectionWithResponseHandler*)connection;
    [con setRawResponse:httpResponse];
     con.data = [[NSMutableData alloc] initWithLength:0];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    LBURLConnectionWithResponseHandler* con = (LBURLConnectionWithResponseHandler*)connection;
    [[con data] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    LBURLConnectionWithResponseHandler* con = (LBURLConnectionWithResponseHandler*)connection;
    NSData* data = [con data];
    NSString* responseString = [[NSString alloc] initWithData:data
                                                     encoding:NSUTF8StringEncoding];
    if([LBHTTPSClient shouldLog]){
    LogDebug(@"Data recieved:%@", responseString);
    }
    LBServerResponse* response = [LBServerResponse handleServerResponse:[con rawResponse]
                                                      responseString:responseString
                                                               error:nil];
    if (con.responseHandler) {
        con.responseHandler(response);
    }
    [self handleErrorIfNeeded:response];
    con.responseHandler = nil;
    [con cancel];
    [con.data setLength:0];
    con = nil;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)connection:(NSURLConnection*)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace
{
    
    BOOL trust = [[protectionSpace authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust];
    return trust;
}
- (void)connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
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
        } else {
            // Create a new Policy - which goes easy on the hostname.
            //
            
            // Extract the chain of certificates provided by the server.
            //
            CFIndex certificateCount = SecTrustGetCertificateCount(challenge.protectionSpace.serverTrust);
            NSMutableArray* chain = [NSMutableArray array];
            
            for (int i = 0; i < certificateCount; i++) {
                SecCertificateRef certRef = SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, i);
                [chain addObject:(__bridge id)(certRef)];
            }
            
            // And create a bland policy which only checks signature paths.
            //
            if (err == errSecSuccess)
                err = SecTrustCreateWithCertificates((__bridge CFArrayRef)(chain),
                                                     SecPolicyCreateBasicX509(), &trust);
#if DEBUG
            LBLogDebug(@"The certificate is NOT expected to match the hostname '%@' ",
                  challenge.protectionSpace.host);
#endif
        };
        
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
    // In this example we can cancel at this point - as we only do
    // canAuthenticateAgainstProtectionSpace against ServerTrust.
    //
    // But in other situations a more gentle continue may be appropriate.
    //
    // [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    
    LBLogDebug(@"Not something we can handle - so we're canceling it.");
    [challenge.sender cancelAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LBURLConnectionWithResponseHandler* con = (LBURLConnectionWithResponseHandler*)connection;
        LBLogDebug(@"%@", [NSString stringWithFormat:@"Did recieve error: %@", [error description]]);
        LBLogDebug(@"%@", [NSString stringWithFormat:@"%@", [[error userInfo] description]]);
        LBLogDebug(@"response:%@",con.rawResponse);

    BOOL shouldRetryRequest = NO;
    if([[self.connectionProperties errorHandler]respondsToSelector:@selector(shouldRetryRequest:forCurrentTry:)]){
        shouldRetryRequest = [[self.connectionProperties errorHandler]shouldRetryRequest:error forCurrentTry:con.retries];
    }

    if (shouldRetryRequest) {
        LBURLConnectionWithResponseHandler* conrestart = [[LBURLConnectionWithResponseHandler alloc] initWithRequest:con.currentRequest
                                                                                                            delegate:self];
        conrestart.responseHandler = con.responseHandler;
        conrestart.requestBody = [con.requestBody copy];
        conrestart.retries = con.retries + 1;
        [conrestart start];
        [con cancel];
        
    } else {
        [con cancel];
        NSData* data = [con data];
        NSString* responseString = [[NSString alloc] initWithData:data
                                                         encoding:NSUTF8StringEncoding];
        LBServerResponse* response = [LBServerResponse handleServerResponse:[con rawResponse]
                                                          responseString:responseString
                                                                   error:error];
        response.currentRequestTryCount = con.retries;
        if (con.responseHandler) {
            con.responseHandler(response);
        }
        con.responseHandler = nil;
        [con.data setLength:0];
        con = nil;
        response.error = error;
        [self handleErrorIfNeeded:response];
    }
}

-(void)handleErrorIfNeeded:(LBServerResponse *)response{
    BOOL shouldDisplayErrorForResponse = NO;
    if([[self.connectionProperties errorHandler]respondsToSelector:@selector(shouldDisplayErrorForResponse:)]){
        shouldDisplayErrorForResponse = [[self.connectionProperties errorHandler]shouldDisplayErrorForResponse:response];
    }
    if(shouldDisplayErrorForResponse){
        NSString *title,*message,*okButton;
        if([[self.connectionProperties errorHandler]respondsToSelector:@selector(titleForErrorForResponse:)]){
        title = [[self.connectionProperties errorHandler]titleForErrorForResponse:response];
        }
        if([[self.connectionProperties errorHandler]respondsToSelector:@selector(messageForErrorForResponse:)]){
        message = [[self.connectionProperties errorHandler]messageForErrorForResponse:response];
        }
        if([[self.connectionProperties errorHandler]respondsToSelector:@selector(titleForOKButtonErrorMessageForResponse:)]){
        okButton = [[self.connectionProperties errorHandler]titleForOKButtonErrorMessageForResponse:response];
        }
        if(!title && !message && !okButton){
            return;
        }
        if(!self.alert || ![[self.alert buttonTitleAtIndex:0]isEqualToString:okButton]){
            self.alert = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:okButton otherButtonTitles: nil];
        }
        if(![self.alert isVisible]){
            [self.alert setTitle:title];
            [self.alert setMessage:message];
            [self.alert show];
        }
    }
}

- (void)sendRequestToPath:(NSString*)path params:(NSDictionary*)params body:(NSString*)body headers:(NSDictionary*)headers method:(NSString*)method responseHandler:(LBServerResponseHandler)responseHandler
{

        LBLogInfo(@"sending %@ request to path:%@",method, path);
        LBLogDebug(@"withParams:%@, andBody:%@, andHeaders:%@,handingResponse:%d", params, body, headers, (responseHandler != nil));

    [self asyncRequestDataFromURL:[NSURL URLWithString:path]
                           method:method
                       parameters:params
                       bodyString:body
                      requestBody:[body dataUsingEncoding:_defaultTextEncoding]
                          headers:headers
         andServerResponseHandler:responseHandler];
}

- (BOOL)addWithRootCA:(NSString*)caDerFilePath strictHostNameCheck:(BOOL)check
{
    
    NSData* derCA = [NSData dataWithContentsOfFile:caDerFilePath];
    if (!derCA) {
        return NO;
    }
    
    SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)derCA);
    if (!caRef) {
        return NO;
    }
    NSArray* chain = [NSArray arrayWithObject:(__bridge id)(caRef)];
    
    return [self initWithRootCAs:chain strictHostNameCheck:check];
}

- (BOOL)initWithRootCAs:(NSArray*)anArrayOfSecCertificateRef strictHostNameCheck:(BOOL)check
{
    
    checkHostname = check;
    caChainArrayRef = CFBridgingRetain(anArrayOfSecCertificateRef);
    
    return YES;
}
- (void)dealloc
{
    if (caChainArrayRef)
        CFRelease(caChainArrayRef);
}

+(BOOL)shouldLog{
   return  [[[LBHTTPSClient sharedClient] connectionProperties]logLevel]==LogLevelDebug;
}
@end
