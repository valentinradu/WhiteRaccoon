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



/*======================================================WRStreamInfo============================================================*/


@implementation WRStreamInfo
@synthesize buffer, bytesConsumedInTotal, bytesConsumedThisIteration, readStream, size, writeStream;

@end



/*======================================================WRBase============================================================*/

@implementation WRBase
@synthesize passive, password, username, schemeId, error;



static NSMutableDictionary *folders;

+ (void)initialize
{    
    static BOOL isCacheInitalized = NO;
    if(!isCacheInitalized)
    {
        isCacheInitalized = YES;
        folders = [[NSMutableDictionary alloc] init];
    }
}


+(NSDictionary *) cachedFolders {
    return folders;
}

+(void) addFoldersToCache:(NSArray *) foldersArray forParentFolderPath:(NSString *) key {
    [folders setObject:foldersArray forKey:key];
}


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
    return [NSURL URLWithString:[fullURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

-(NSString *)path {
    //  we remove all the extra slashes from the directory path, including the last one (if there is one)
    //  we also escape it
    NSString * escapedPath = [path stringByStandardizingPath];   
    
    
    //  we need the path to be absolute, if it's not, we *make* it
    if (![escapedPath isAbsolutePath]) {
        escapedPath = [@"/" stringByAppendingString:escapedPath];
    }
    
    return escapedPath;
}


-(void) setPath:(NSString *)directoryPathLocal {
    path = directoryPathLocal;
}



-(NSString *)scheme {
    switch (self.schemeId) {
        case kWRFTP:
            return @"ftp";
            break;
            
        default:
            InfoLog(@"The scheme id was not recognized! Default FTP set!");
            return @"ftp";
            break;
    }
    
    return @"";
}

-(NSString *) hostname {
    return [hostname stringByStandardizingPath];
}

-(void)setHostname:(NSString *)hostnamelocal {
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
    
    return [cred stringByStandardizingPath];
}




-(void) start{
}

-(void) destroy{
    
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
    if(!request.passive)request.passive = self.passive;
    if(!request.password)request.password = self.password;
    if(!request.username)request.username = self.username;
    if(!request.hostname)request.hostname = self.hostname;
    
    if (tailRequest == nil){
        tailRequest = request;
    }else{
        
        
        tailRequest.nextRequest = request;
        request.prevRequest = tailRequest;
        
        
        tailRequest = request;
    }
    
    if (headRequest == nil) {
        headRequest = tailRequest;        
    }    
}

-(void) addRequestInFront:(WRRequest *) request {
    request.delegate = self;
    if(!request.passive)request.passive = self.passive;
    if(!request.password)request.password = self.password;
    if(!request.username)request.username = self.username;
    if(!request.hostname)request.hostname = self.hostname;
    
    if (headRequest != nil) {
        
        request.nextRequest = headRequest.nextRequest;
        request.nextRequest.prevRequest = request;
        
        headRequest.nextRequest = request;
        request.prevRequest = headRequest.nextRequest;
    }else{
        InfoLog(@"Adding in front of the queue request at least one element already in the queue. Use 'addRequest' otherwise.");
        return;
    }
    
    if (tailRequest == nil) {
        tailRequest = request;        
    }
    
    
}

-(void) addRequestsFromArray: (NSArray *) array{
    //TBD
}

-(void) removeRequestFromQueue:(WRRequest *) request {
    
    if ([headRequest isEqual:request]) {
        headRequest = request.nextRequest;
    }
    
    if ([tailRequest isEqual:request]) {
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

-(void) destroy{    
    [headRequest destroy];
    headRequest.nextRequest = nil;
    [super destroy];
}


// delegate methods

-(void) requestCompleted:(WRRequest *) request {
    [self.delegate requestCompleted:request];
    
    headRequest = headRequest.nextRequest;
    
    if (headRequest==nil) {
       [self.delegate queueCompleted:self];
    }else{
       [headRequest start]; 
    }
}

-(void) requestFailed:(WRRequest *) request{    
    [self.delegate requestFailed:request];
    
    headRequest = headRequest.nextRequest;    
    
    [headRequest start];
}

-(BOOL) shouldOverwriteFileWithRequest:(WRRequest *)request {
    if (![self.delegate respondsToSelector:@selector(shouldOverwriteFileWithRequest:)]) {
        return NO;
    }else{
        return [self.delegate shouldOverwriteFileWithRequest:request];
    }
}




@end














/*======================================================WRRequest============================================================*/

@implementation WRRequest
@synthesize type, nextRequest, prevRequest, delegate, streamInfo, didManagedToOpenStream;

- (id)init {
    self = [super init];
    if (self) {
        streamInfo = [[WRStreamInfo alloc] init];
        self.streamInfo.readStream = nil;
        self.streamInfo.writeStream = nil;
        self.streamInfo.bytesConsumedThisIteration = 0;
        self.streamInfo.bytesConsumedInTotal = 0;
        
        free(self.streamInfo.buffer);
        self.streamInfo.buffer = calloc(kWRDefaultBufferSize, sizeof(UInt8));
    }
    return self;
}

-(void)destroy {
    
    self.streamInfo.bytesConsumedThisIteration = 0;
    self.streamInfo.bytesConsumedInTotal = 0;
    [super destroy];
}

-(void)dealloc {
    
    free(streamInfo.buffer);
    
    
}

@end















/*======================================================WRRequestDownload============================================================*/

@implementation WRRequestDownload
@synthesize receivedData;

-(WRRequestTypes)type {
    return kWRDownloadRequest;
}



-(void) start{
    
    if (self.hostname==nil) {
        InfoLog(@"The host name is nil!");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientHostnameIsNil;
        [self.delegate requestFailed:self];
        return;
    }
    
    // a little bit of C because I was not able to make NSInputStream play nice
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)self.fullURL);
    self.streamInfo.readStream = (NSInputStream *)CFBridgingRelease(readStreamRef);
    
    if (self.streamInfo.readStream==nil) {
        InfoLog(@"Can't open the read stream! Possibly wrong URL");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientCantOpenStream;
        [self.delegate requestFailed:self];
        return;
    }
    
    
    self.streamInfo.readStream.delegate = self;
	[self.streamInfo.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.streamInfo.readStream open];
    
    self.didManagedToOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kWRDefaultTimeout * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        if (!self.didManagedToOpenStream&&self.error==nil) {
            InfoLog(@"No response from the server. Timeout.");
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = kWRFTPClientStreamTimedOut;
            [self.delegate requestFailed:self];
            [self destroy];
        }
    });
}

//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            self.didManagedToOpenStream = YES;
            self.streamInfo.bytesConsumedInTotal = 0;
            self.receivedData = [NSMutableData data];
        } break;
        case NSStreamEventHasBytesAvailable: {
            
            self.streamInfo.bytesConsumedThisIteration = [self.streamInfo.readStream read:self.streamInfo.buffer maxLength:kWRDefaultBufferSize];
            
            if (self.streamInfo.bytesConsumedThisIteration!=-1) {
                if (self.streamInfo.bytesConsumedThisIteration!=0) {
                    NSMutableData *receivedMutableData = (NSMutableData *) self.receivedData;
                    [receivedMutableData appendBytes:self.streamInfo.buffer length:self.streamInfo.bytesConsumedThisIteration];
                }
            }else{
                InfoLog(@"Stream opened, but failed while trying to read from it.");
                self.error = [[WRRequestError alloc] init];
                self.error.errorCode = kWRFTPClientCantReadStream;
                [self.delegate requestFailed:self];
                [self destroy];
            }
            
        } break;
        case NSStreamEventHasSpaceAvailable: {
            
        } break;
        case NSStreamEventErrorOccurred: {
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = [self.error errorCodeWithError:[theStream streamError]];
            InfoLog(@"%@", self.error.message);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
            
        case NSStreamEventEndEncountered: {
            [self.delegate requestCompleted:self]; 
            [self destroy];
        } break;
            
        case NSStreamEventNone:
        {
            ;
        }break;
    }
}

-(void) destroy{
    
    if (self.streamInfo.readStream) {
        [self.streamInfo.readStream close];
        [self.streamInfo.readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.streamInfo.readStream = nil;
    }
    
    [super destroy];
}


@end
















/*======================================================WRRequestDelete============================================================*/

@implementation WRRequestDelete

-(WRRequestTypes)type {
    return kWRDeleteRequest;
}

-(NSString *)path {
    
    NSString * lastCharacter = [path substringFromIndex:[path length] - 1];
    isDirectory = ([lastCharacter isEqualToString:@"/"]);
    
    if (!isDirectory) return [super path];
    
    NSString * directoryPath = [super path];
    if (![directoryPath isEqualToString:@""]) {
        directoryPath = [directoryPath stringByAppendingString:@"/"];
    }
    return directoryPath;
}

-(void) start{
    
    if (self.hostname==nil) {
        InfoLog(@"The host name is nil!");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientHostnameIsNil;
        [self.delegate requestFailed:self];
        return;
    }
    
    CFURLDestroyResource((__bridge CFURLRef)self.fullURL, NULL);
}

-(void) destroy{
    [super destroy];  
}


@end
















/*======================================================WRRequestUpload============================================================*/

@interface WRRequestUpload () //note the empty category name
-(void)upload;
@end

@implementation WRRequestUpload
@synthesize listrequest, sentData;

-(WRRequestTypes)type {
    return kWRUploadRequest;
}

-(void) start{
    
    if (self.hostname==nil) {
        InfoLog(@"The host name is nil!");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientHostnameIsNil;
        [self.delegate requestFailed:self];
        return;
    }   
    
    //we first list the directory to see if our folder is up already
    
    self.listrequest = [[WRRequestListDirectory alloc] init];    
    self.listrequest.path = [self.path stringByDeletingLastPathComponent];
    self.listrequest.hostname = self.hostname;
    self.listrequest.username = self.username;
    self.listrequest.password = self.password;
    self.listrequest.delegate = self;
    [self.listrequest start];
}

-(void) requestCompleted:(WRRequest *) request{
    
    BOOL fileAlreadyExists = NO;
    NSString * fileName = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
    for (NSDictionary * file in self.listrequest.filesInfo) {
        NSString * name = [file objectForKey:(id)kCFFTPResourceName];
        if ([fileName isEqualToString:name]) {
            fileAlreadyExists = YES;
        }
    }
    
    
    if (fileAlreadyExists) {
        if (![self.delegate shouldOverwriteFileWithRequest:self]) {
            InfoLog(@"There is already a file/folder with that name and the delegate decided not to overwrite!");
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = kWRFTPClientFileAlreadyExists;
            [self.delegate requestFailed:self];
            [self destroy];
        }else{
            //unfortunately, for FTP there is no current solution for deleting/overwriting a folder (or I was not able to find one yet)
            //it will fail with permission error
            
            if (self.type!=kWRCreateDirectoryRequest) {
                [self upload];
            }else{
                InfoLog(@"Unfortunately, at this point, the library doesn't support directory overwriting.");
                self.error = [[WRRequestError alloc] init];
                self.error.errorCode = kWRFTPClientCantOverwriteDirectory;
                [self.delegate requestFailed:self];
                [self destroy];
            }
        }
    }else{
        [self upload];
    }    
}


-(void) requestFailed:(WRRequest *) request{
    [self.delegate requestFailed:request];
}

-(void)upload {
    // a little bit of C because I was not able to make NSInputStream play nice
    CFWriteStreamRef writeStreamRef = CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)self.fullURL);
    self.streamInfo.writeStream = (NSOutputStream *)CFBridgingRelease(writeStreamRef);
    
    if (self.streamInfo.writeStream==nil) {
        InfoLog(@"Can't open the write stream! Possibly wrong URL!");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientCantOpenStream;
        [self.delegate requestFailed:self];
        return;
    }
    
    
    if (self.sentData==nil) {
        InfoLog(@"Trying to send nil data? No way. Abort");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientSentDataIsNil;
        [self.delegate requestFailed:self];
        [self destroy];
    }else{
        self.streamInfo.writeStream.delegate = self;
        [self.streamInfo.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.streamInfo.writeStream open];
    }
    
    
    self.didManagedToOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kWRDefaultTimeout * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        if (!self.didManagedToOpenStream&&self.error==nil) {
            InfoLog(@"No response from the server. Timeout.");
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = kWRFTPClientStreamTimedOut;
            [self.delegate requestFailed:self];
            [self destroy];
        }
    });
}


//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            self.didManagedToOpenStream = YES;
            self.streamInfo.bytesConsumedInTotal = 0;
        } break;
        case NSStreamEventHasBytesAvailable: {
            
        } break;
        case NSStreamEventHasSpaceAvailable: {
            
            uint8_t * nextPackage;
            NSUInteger nextPackageLength = MIN(kWRDefaultBufferSize, self.sentData.length-self.streamInfo.bytesConsumedInTotal);
            
            nextPackage = malloc(nextPackageLength);
            
            [self.sentData getBytes:nextPackage range:NSMakeRange(self.streamInfo.bytesConsumedInTotal, nextPackageLength)];
            self.streamInfo.bytesConsumedThisIteration = [self.streamInfo.writeStream write:nextPackage maxLength:nextPackageLength];
            
            free(nextPackage);
            
            if (self.streamInfo.bytesConsumedThisIteration!=-1) {
                if (self.streamInfo.bytesConsumedInTotal + self.streamInfo.bytesConsumedThisIteration<self.sentData.length) {
                    self.streamInfo.bytesConsumedInTotal += self.streamInfo.bytesConsumedThisIteration;
                }else{
                    [self.delegate requestCompleted:self]; 
                    self.sentData =nil;
                    [self destroy];
                }
            }else{
                InfoLog(@"");
                self.error = [[WRRequestError alloc] init];
                self.error.errorCode = kWRFTPClientCantWriteStream;
                [self.delegate requestFailed:self];
                [self destroy];
            }
            
        } break;
        case NSStreamEventErrorOccurred: {
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = [self.error errorCodeWithError:[theStream streamError]];
            InfoLog(@"%@", self.error.message);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
            
        case NSStreamEventEndEncountered: {
            InfoLog(@"The stream was closed by server while we were uploading the data. Upload failed!");
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = kWRFTPServerAbortedTransfer;
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
            
            
        case NSStreamEventNone:
        {
            ;
        }break;
    }
}



-(void) destroy{
    
    if (self.streamInfo.writeStream) {
        
        [self.streamInfo.writeStream close];
        [self.streamInfo.writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.streamInfo.writeStream = nil;
        
    }
    
    
    [super destroy];
}



@end




















/*======================================================WRRequestCreateDirectory============================================================*/

@implementation WRRequestCreateDirectory

-(WRRequestTypes)type {
    return kWRCreateDirectoryRequest;
}

-(NSString *)path {
    //  the path will always point to a directory, so we add the final slash to it (if there was one before escaping/standardizing, it's *gone* now)
    NSString * directoryPath = [super path];
    if (![directoryPath isEqualToString:@""]) {
        directoryPath = [directoryPath stringByAppendingString:@"/"];
    }
    return directoryPath;
}

-(void) upload {
    CFWriteStreamRef writeStreamRef = CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)self.fullURL);
    self.streamInfo.writeStream = (NSOutputStream *)CFBridgingRelease(writeStreamRef);
    
    if (self.streamInfo.writeStream==nil) {
        InfoLog(@"Can't open the write stream! Possibly wrong URL!");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientCantOpenStream;
        [self.delegate requestFailed:self];
        return;
    }
    
    self.streamInfo.writeStream.delegate = self;
    [self.streamInfo.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.streamInfo.writeStream open];
    
    self.didManagedToOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kWRDefaultTimeout * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        if (!self.didManagedToOpenStream&&self.error==nil) {
            InfoLog(@"No response from the server. Timeout.");
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = kWRFTPClientStreamTimedOut;
            [self.delegate requestFailed:self];
            [self destroy];
        }
    });
}


//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            self.didManagedToOpenStream = YES;
        } break;
        case NSStreamEventHasBytesAvailable: {
        
        } break;
        case NSStreamEventHasSpaceAvailable: {
            
        } break;
        case NSStreamEventErrorOccurred: {
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = [self.error errorCodeWithError:[theStream streamError]];
            InfoLog(@"%@", self.error.message);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
        case NSStreamEventEndEncountered: {
            [self.delegate requestCompleted:self];
            [self destroy];
        } break;
            
        case NSStreamEventNone:
        {
            ;
        }break;
    }
}

@end














/*======================================================WRRequestListDir============================================================*/

@implementation WRRequestListDirectory
@synthesize filesInfo;


-(WRRequestTypes)type {
    return kWRListDirectoryRequest;
}

-(NSString *)path {
    //  the path will always point to a directory, so we add the final slash to it (if there was one before escaping/standardizing, it's *gone* now)
    NSString * directoryPath = [super path];
    if (![directoryPath isEqualToString:@""]) {
        directoryPath = [directoryPath stringByAppendingString:@"/"];
    }
    return directoryPath;
}

-(void) start {
    if (self.hostname==nil) {
        InfoLog(@"The host name is not valid!");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientHostnameIsNil;
        [self.delegate requestFailed:self];
        return;
    }
    
    // a little bit of C because I was not able to make NSInputStream play nice
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)self.fullURL);
    self.streamInfo.readStream = (NSInputStream *)CFBridgingRelease(readStreamRef);
    
    
    if (self.streamInfo.readStream==nil) {
        InfoLog(@"Can't open the write stream! Possibly wrong URL!");
        self.error = [[WRRequestError alloc] init];
        self.error.errorCode = kWRFTPClientCantOpenStream;
        [self.delegate requestFailed:self];
        return;
    }
    
    
    self.streamInfo.readStream.delegate = self;
	[self.streamInfo.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.streamInfo.readStream open];
    
    self.didManagedToOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kWRDefaultTimeout * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        if (!self.didManagedToOpenStream&&self.error==nil) {
            InfoLog(@"No response from the server. Timeout.");
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = kWRFTPClientStreamTimedOut;
            [self.delegate requestFailed:self];
            [self destroy];
        }
    });

}

//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
			self.filesInfo = [NSMutableArray array];
            self.didManagedToOpenStream = YES;
        } break;
        case NSStreamEventHasBytesAvailable: {
            
            
            self.streamInfo.bytesConsumedThisIteration = [self.streamInfo.readStream read:self.streamInfo.buffer maxLength:kWRDefaultBufferSize];
            
            if (self.streamInfo.bytesConsumedThisIteration!=-1) {
                if (self.streamInfo.bytesConsumedThisIteration!=0) {
                    NSUInteger  offset = 0;
                    CFIndex     parsedBytes;
                    
                    do {        
                        
                        CFDictionaryRef listingEntity = NULL;
                        
                        parsedBytes = CFFTPCreateParsedResourceListing(NULL, &self.streamInfo.buffer[offset], self.streamInfo.bytesConsumedThisIteration - offset, &listingEntity);
                        
                        if (parsedBytes > 0) {
                            if (listingEntity != NULL) {            
                                self.filesInfo = [self.filesInfo arrayByAddingObject:(NSDictionary *)CFBridgingRelease(listingEntity)];
                            }            
                            offset += parsedBytes;            
                        }
                        
                    } while (parsedBytes>0); 
                }
            }else{
                InfoLog(@"Stream opened, but failed while trying to read from it.");
                self.error = [[WRRequestError alloc] init];
                self.error.errorCode = kWRFTPClientCantReadStream;
                [self.delegate requestFailed:self];
                [self destroy];
            }
            
            
        } break;
        case NSStreamEventHasSpaceAvailable: {
            
        } break;
        case NSStreamEventErrorOccurred: {
            self.error = [[WRRequestError alloc] init];
            self.error.errorCode = [self.error errorCodeWithError:[theStream streamError]];
            InfoLog(@"%@", self.error.message);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
        case NSStreamEventEndEncountered: {            
            [WRBase addFoldersToCache:self.filesInfo forParentFolderPath:self.path];
            [self.delegate requestCompleted:self]; 
            [self destroy];
        } break;
            
            
        case NSStreamEventNone:
        {
            ;
        }break;
    }
}



@end
















/*======================================================WRRequestError============================================================*/

@implementation WRRequestError
@synthesize errorCode;

- (id)init {
    self = [super init];
    if (self) {
        self.errorCode = 0;
    }
    return self;
}

-(NSString *) message {
    NSString * mess;
    switch (self.errorCode) {
        //Client errors
        case kWRFTPClientCantOpenStream:
            mess = @"Can't open stream, probably the URL is wrong.";
            break;
            
        case kWRFTPClientStreamTimedOut:
            mess = @"No response from the server. Timeout.";
            break;
            
        case kWRFTPClientCantReadStream:
            mess = @"Stream opened, but failed while trying to read from it.";
            break;
            
        case kWRFTPClientCantWriteStream:
            mess = @"The write stream had opened, but it failed when we tried to write data on it!";
            break;
            
        case kWRFTPClientHostnameIsNil:
            mess = @"Hostname can't be nil.";
            break;
            
        case kWRFTPClientSentDataIsNil:
            mess = @"You need some data to send. Why is 'sentData' nil?";
            break;
            
        case kWRFTPClientCantOverwriteDirectory:
            mess = @"Can't overwrite directory!";
            break;
            
        case kWRFTPClientFileAlreadyExists:
            mess = @"File already exists!";
            break;
            
            
            
        //Server errors    
        case kWRFTPServerAbortedTransfer:
            mess = @"Server connection interrupted.";
            break;
            
        case kWRFTPServerCantOpenDataConnection:
            mess = @"Server can't open data connection.";
            break;
            
        case kWRFTPServerFileNotAvailable:
            mess = @"No such file or directory on server.";
            break;
            
        case kWRFTPServerIllegalFileName:
            mess = @"File name has illegal characters.";
            break;
            
        case kWRFTPServerResourceBusy:
            mess = @"Resource busy! Try later!";
            break;
            
        case kWRFTPServerStorageAllocationExceeded:
            mess = @"Server storage exceeded!";
            break;
            
        case kWRFTPServerUnknownError:
            mess = @"Unknown FTP error!";
            break;
            
        case kWRFTPServerUserNotLoggedIn:
            mess = @"Not logged in.";
            break;
            
        default:
            mess = @"Unknown error!";
            break;
    }
    
    return mess;
}


-(WRErrorCodes) errorCodeWithError:(NSError *) error {

    
    WRErrorCodes code = [[error.userInfo objectForKey:(NSString*)kCFFTPStatusCodeKey] intValue];
    
    return code;
}


@end

