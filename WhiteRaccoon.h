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

@class WRRequest;
@class WRRequestQueue;
@class WRRequestError;

/*======================================================Global Constants and Enums============================================================*/

typedef enum {
    kWRUploadRequest,
	kWRDownloadRequest,
    kWRCreateDirectoryRequest,
	kWRListDirectoryRequest
} WRRequestTypes;








/*======================================================WRRequestDelegate============================================================*/

@protocol WRRequestDelegate  <NSObject>

@required
-(void) requestCompleted:(WRRequest *) request;
-(void) requestFailed:(WRRequest *) request;


@end










/*======================================================WRBase============================================================*/
//Abstract class, do not instantiate
@interface WRBase : NSObject {
    
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * passive;

@end









/*======================================================WRRequest============================================================*/

@interface WRRequest : WRBase {
    
}

@property (nonatomic, retain) WRRequest * nextRequest;
@property (nonatomic, retain) WRRequest * prevRequest;
@property (nonatomic, retain) WRRequestError * error;
@property (nonatomic, retain) id result;
@property (nonatomic, retain) NSNumber * type;

@property (nonatomic, retain) id<WRRequestDelegate> delegate;

-(void) start;
-(void) cancel;

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
-(void) addRequestsFromArray: (NSArray *) array;
-(void) removeRequestFromQueue:(WRRequest *) request;

-(void) start;
-(void) cancel;

@end











/*======================================================WRRequestError============================================================*/

@interface WRRequestError : NSObject {
    
}

@property (nonatomic, retain) NSString * message;

@end



