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
@synthesize passive, password, username, schemeId;

- (id)init {
    self = [super init];
    if (self) {
        self.schemeId = kWRFTP;
        self.passive = NO;
        self.password = nil;
        self.username = nil;
        self.hostname = nil;
        self.path = @"";
    }
    return self;
}

-(NSURL*) fullURL {
    // first we merge all the url parts into one big and beautiful url
    NSString * fullURLString = [self.scheme stringByAppendingFormat:@"%@%@%@%@", @"://", self.credentials, self.hostname, self.path];       
    return [NSURL URLWithString:fullURLString];
}

-(NSString *)path {
    //  we remove all the extra slashes from the directory path, including the last one (if there is one)
    //  we also escape it
    NSString * escapedPath = [[path stringByStandardizingPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];   
    
    
    //  we need the path to be absolute, if it's not, we *make* it
    if (![escapedPath isAbsolutePath]) {
        escapedPath = [@"/" stringByAppendingString:escapedPath];
    }
    
    return escapedPath;
}


-(void) setPath:(NSString *)directoryPathLocal {
    [directoryPathLocal retain];
    [path release];
    path = directoryPathLocal;
}



-(NSString *)scheme {
    switch (self.schemeId) {
        case kWRFTP:
            return @"ftp";
            break;
    }
    
    return @"";
}

-(NSString *) hostname {
    return [hostname stringByStandardizingPath];
}

-(void)setHostname:(NSString *)hostnamelocal {
    [hostnamelocal retain];
    [hostname release];
    hostname = hostnamelocal;
}

-(NSString *) credentials {    
    
    NSString * cred;
    
    if (self.username!=nil) {
        if (self.password!=nil) {
            cred = [NSString stringWithFormat:@"%@:%@@", self.username, self.password];
        }else{
            cred = [NSString stringWithFormat:@"%@@", self.username];
        }
    }else{
        cred = @"";
    }
    
    return [[cred stringByStandardizingPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];;
}




-(void) start{
}

-(void) destroy{
    
}

- (void)dealloc {
    [password release];
    [hostname release];
    [username release];
    [path release];
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
    request.hostname = self.hostname;
    
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
    [super start];
    [headRequest start];
}

-(void) destroy{
    [super destroy];
    [headRequest destroy];
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
@synthesize type, error, nextRequest, prevRequest, delegate;

-(void)dealloc {
    [error release];
    [nextRequest release];
    [prevRequest release];
    [delegate release];
    
    
    [super dealloc];
}

@end















/*======================================================WRRequestDownload============================================================*/

@implementation WRRequestDownload



-(void) start{    
    [super start];
    
    if (self.hostname==nil) {
        NSLog(@"the address is nil error");
        [self.delegate requestFailed:self];
        return;
    }
    
    // a little bit of C because I was not able to make NSInputStream play nice
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(NULL, (CFURLRef)self.fullURL);
    streamInfo.readStream = (NSInputStream *)readStreamRef;
    
    if (streamInfo.readStream==nil) {
        NSLog(@"the address is incorect");
        [self.delegate requestFailed:self];
        return;
    }
    
	[streamInfo.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[streamInfo.readStream open];
}

-(void) destroy{
    [super destroy];
    
    [streamInfo.readStream close];
    [streamInfo.readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [streamInfo.readStream release];
    streamInfo.readStream = nil;
    streamInfo.consumedBytes = 0;
    streamInfo.leftoverBytes = 0;
    
}

-(void)dealloc {
    [super dealloc];
}

@end

















/*======================================================WRRequestUpload============================================================*/

@implementation WRRequestUpload

-(WRRequestTypes)type {
    return kWRDownloadRequest;
}

-(void) start{    
    [super start];
    
    if (self.hostname==nil) {
        NSLog(@"the address is nil error");
        [self.delegate requestFailed:self];
        return;
    }
    
    // a little bit of C because I was not able to make NSInputStream play nice
    CFWriteStreamRef writeStreamRef = CFWriteStreamCreateWithFTPURL(NULL, (CFURLRef)self.fullURL);
    streamInfo.writeStream = (NSOutputStream *)writeStreamRef;
    
    if (streamInfo.writeStream==nil) {
        NSLog(@"the address is incorect");
        [self.delegate requestFailed:self];
        return;
    }
    
	[streamInfo.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[streamInfo.writeStream open];
}

-(void) destroy{
    [super destroy];
    
    [streamInfo.writeStream close];
    [streamInfo.writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [streamInfo.writeStream release];
    streamInfo.writeStream = nil;
    streamInfo.consumedBytes = 0;
    streamInfo.leftoverBytes = 0;
    
}

@end














/*======================================================WRRequestListDir============================================================*/

@implementation WRRequestListDir
@synthesize filesInfo;


-(WRRequestTypes)type {
    return kWRListDirectoryRequest;
}

-(NSString *)path {
    //  the path will always point to a directory, so we add the final slash to it (if there was one before escaping/standardizing, it's *gone* now)
    return [[super path] stringByAppendingString:@"/"];
}

-(void) start {
    [super start];
    streamInfo.readStream.delegate = self;
}

//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
			self.filesInfo = [NSMutableArray array];
        } break;
        case NSStreamEventHasBytesAvailable: {
            
            
            streamInfo.consumedBytes = [streamInfo.readStream read:streamInfo.buffer maxLength:kWRDefaultBufferSize];
            
            if (streamInfo.consumedBytes!=-1) {
                if (streamInfo.consumedBytes==0) {
                   [self.delegate requestCompleted:self]; 
                   [self destroy]; 
                }else{
                    NSUInteger  offset = 0;
                    CFIndex     parsedBytes;
                    
                    do {        
                        
                        CFDictionaryRef listingEntity = NULL;
                        
                        parsedBytes = CFFTPCreateParsedResourceListing(NULL, &streamInfo.buffer[offset], streamInfo.consumedBytes - offset, &listingEntity);
                        
                        if (parsedBytes > 0) {
                            if (listingEntity != NULL) {            
                                [self.filesInfo addObject:(NSDictionary *)listingEntity];                            
                            }            
                            offset += parsedBytes;            
                        }
                        
                        if (listingEntity != NULL) {            
                            CFRelease(listingEntity);            
                        }                    
                    } while (parsedBytes>0); 
                }
            }else{
                NSLog(@"Stream read failed. Abort!");
                [self.delegate requestFailed:self];
                [self destroy];
            }
            
            
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"hasspce");
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"errror: %@", [theStream streamError]);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
        case NSStreamEventEndEncountered: {
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
    }
}


-(void)dealloc {    
    [filesInfo release];
    [super dealloc];
}

@end

