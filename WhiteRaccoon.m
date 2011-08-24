//  WhiteRaccoon
//
//  Created by Valentin Radu on 8/23/11.
//  Copyright 2011 Valentin Radu. All rights reserved.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "WhiteRaccoon.h"









/*======================================================WRBase============================================================*/

@implementation WRBase
@synthesize passive, password, username, address;

- (void)dealloc {
    [passive release];
    [password release];
    [address release];
    [username release];
    [super dealloc];
}

@end






/*======================================================WRRequestQueue============================================================*/

@implementation WRRequestQueue
@synthesize delegate;

- (id)init {
    self = [super init];
    if (self) {
        headRequest = nil;
        tailRequest = nil;
    }
    return self;
}

-(void) addRequest:(WRRequest *) request{
    
    request.delegate = self;
    request.passive = self.passive;
    request.password = self.password;
    request.username = self.username;
    request.address = self.address;
    
    if (tailRequest == nil){
        [request retain];
        tailRequest = request;
    }else{
        
        tailRequest.nextRequest = request;
        request.prevRequest = tailRequest;
        
        [request retain];
        [tailRequest release];
        tailRequest = request;
    }
    
    if (headRequest == nil) {
        [tailRequest retain];
        headRequest = tailRequest;        
    }    
}

-(void) addRequestsFromArray: (NSArray *) array{
    
}

-(void) removeRequestFromQueue:(WRRequest *) request {
    
    if ([headRequest isEqual:request]) {
        [request.nextRequest retain];
        [headRequest release];
        headRequest = request.nextRequest;
    }
    
    if ([tailRequest isEqual:request]) {
        [request.nextRequest retain];
        [tailRequest release];
        tailRequest = request.prevRequest;
    }
    
    request.prevRequest.nextRequest = request.nextRequest;
    request.nextRequest.prevRequest = request.prevRequest;
    
    request.nextRequest = nil;
    request.prevRequest = nil;
}

-(void) start{    
    [headRequest start];
}

-(void) cancel{
    [headRequest cancel];
    headRequest.nextRequest = nil;
}


// delegate methods

-(void) requestCompleted:(WRRequest *) request {
    
    [headRequest.nextRequest retain];
    [headRequest release];
    headRequest = headRequest.nextRequest;
    
    [headRequest start];
    
    [self.delegate requestCompleted:request];
}

-(void) requestFailed:(WRRequest *) request{
    
    [self.delegate requestFailed:request];
}

-(void)dealloc {
    [headRequest release];
    [tailRequest release];
    [delegate release];
    [super dealloc];
}

@end














/*======================================================WRRequest============================================================*/

@implementation WRRequest
@synthesize type, error, result, nextRequest, prevRequest, delegate;

-(void) start{
    [self.delegate performSelector:@selector(requestCompleted:) withObject:self afterDelay:1];
}

-(void) cancel{

}

-(void)dealloc {
    [type release];
    [error release];
    [result release];
    [nextRequest release];
    [prevRequest release];
    [delegate release];
    
    
    [super dealloc];
}

@end
