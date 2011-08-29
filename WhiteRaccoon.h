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

#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>

@class WRRequest;
@class WRRequestQueue;
@class WRRequestError;
@class WRRequestListDir;

/*======================================================Global Constants, Variables, Structs and Enums============================================================*/

typedef enum {
    kWRUploadRequest,
	kWRDownloadRequest,
    kWRCreateDirectoryRequest,
	kWRListDirectoryRequest
} WRRequestTypes;


typedef enum {
    kWRFTP
} WRSchemes;


typedef enum {
    kWRDefaultBufferSize = 32768
} WRBufferSizes;


typedef struct WRStreamInfo {
    
    NSOutputStream    *writeStream;    
    NSInputStream     *readStream;
    UInt32            bytesConsumedThisIteration;    
    UInt32            bytesConsumedInTotal;
    SInt64            size;
    UInt8             buffer[kWRDefaultBufferSize];
    
} WRStreamInfo;









/*======================================================WRRequestDelegate============================================================*/

@protocol WRRequestDelegate  <NSObject>

@required
-(void) requestCompleted:(WRRequest *) request;
-(void) requestFailed:(WRRequest *) request;

@optional
-(BOOL) shouldOverwriteFileWithRequest: (WRRequest *) request;


@end










/*======================================================WRBase============================================================*/
//Abstract class, do not instantiate
@interface WRBase : NSObject {
@protected 
    NSString * path;
    NSString * hostname;
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, assign) WRSchemes schemeId;
@property (nonatomic, readonly) NSString * scheme;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * hostname;
@property (nonatomic, readonly) NSString * credentials;
@property (nonatomic, readonly) NSURL * fullURL;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, assign) BOOL passive;

-(void) start;
-(void) destroy;

+(NSDictionary *) cachedFolders;
+(void) addFoldersToCache:(NSArray *) foldersArray forParentFolderPath:(NSString *) key;

@end









/*======================================================WRRequest============================================================*/

@interface WRRequest : WRBase {
    @protected
    WRStreamInfo streamInfo;
}

@property (nonatomic, retain) WRRequest * nextRequest;
@property (nonatomic, retain) WRRequest * prevRequest;
@property (nonatomic, retain) WRRequestError * error;
@property (nonatomic, readonly) WRRequestTypes type;
@property (nonatomic, retain) id<WRRequestDelegate> delegate;

@end









/*======================================================WRRequestDownload============================================================*/

@interface WRRequestDownload : WRRequest<NSStreamDelegate> {
  
}

@property (nonatomic, retain) NSMutableData * receivedData;

@end










/*======================================================WRRequestUpload============================================================*/

@interface WRRequestUpload : WRRequest<WRRequestDelegate, NSStreamDelegate> {
    
}

@property (nonatomic, retain) WRRequestListDir * listrequest;
@property (nonatomic, retain) NSMutableData * sentData;

@end










/*======================================================WRRequestCreateDirectory============================================================*/

@interface WRRequestCreateDirectory : WRRequestUpload<NSStreamDelegate> {
    
}

@end










/*======================================================WRRequestListDir============================================================*/

@interface WRRequestListDir : WRRequestDownload<NSStreamDelegate> {
   
}

@property (nonatomic, retain) NSMutableArray * filesInfo;


@end











/*======================================================WRRequestQueue============================================================*/

//  Used to add requests (read, write) to a queue.
//  The request will be sent to the server in the order in which they were added.
//  If an error occures on one of the operations

@interface WRRequestQueue : WRBase<WRRequestDelegate> {
   @private
    WRRequest * headRequest;
    WRRequest * tailRequest;
    
}

@property (nonatomic, retain) id<WRRequestDelegate> delegate;

-(void) addRequest:(WRRequest *) request;
-(void) addRequestInFront:(WRRequest *) request;
-(void) addRequestsFromArray: (NSArray *) array;
-(void) removeRequestFromQueue:(WRRequest *) request;

@end











/*======================================================WRRequestError============================================================*/

@interface WRRequestError : NSObject {
    
}

@property (nonatomic, retain) NSString * message;

@end



