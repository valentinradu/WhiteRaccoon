### General notes

You can use WhiteRaccoon to interact with FTP servers in one of two ways: either make a simple request and send it right away to the FTP server or add several requests to a queue and the queue will send them one by one in the order in which they were added.


WhiteRaccoon supports the following FTP operations:
*   Download file
*   Upload file (if the file is already on the server the delegate will be asked if the file can be overwritten)
*   Delete file
*   Delete directory (only if the directory is empty)
*   Create directory
*   List directory contents (returns an array of dictionaries, each of the dictionaries has the keys described [here](http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFFTPStreamRef/Reference/reference.html#//apple_ref/doc/c_ref/kCFFTPResourceMode)


### Simple usage

#### Download file





### Queue usage

Here is how you can use a queue request to create a directory and then add an image in it.

        - upload
        {

            //we alloc and init the our request queue
            WRRequestQueue * requestsQueue = [[WRRequestQueue alloc] init];

            //we set the delegate to self
            requestsQueue.delegate = self;

            //we set the credentials and hostname
            //every request added to the queue will use them if it doesn't have its own credentials and/or hostname
            //for anonymous login just leave the username and password nil
            requestsQueue.hostname = @"xxx.xxx.xxx.xxx";
            requestsQueue.username = @"myuser";
            requestsQueue.password = @"mypass";


            //and now, we start to create our requests and add them to the queue
            //the requests will be executed in the order in which you add them, one by one


            //we first create a directory
            //we can safely autorelease the request object because the queue takes ownership of it in addRequest: method
            WRRequestCreateDirectory * createDir = [[[WRRequestCreateDirectory alloc] init] autorelease];
            createDir.path = @"/dummyDir/";
            [requestsQueue addRequest:createDir];


            //then we upload the file in our newly created directory
            //the upload request needs the input data to be NSData 
            //so we first convert the image to NSData
            UIImage * ourImage = [UIImage imageNamed:@"space.jpg"];
            NSData * ourImageData = UIImageJPEGRepresentation(ourImage, 100);

            WRRequestUpload * uploadImage = [[[WRRequestUpload alloc] init] autorelease];
            uploadImage.sentData = [[ourImageData mutableCopy] autorelease];
            //we put the file in the directory we created with the previous request
            uploadImage.path = @"/dummyDir/image.jpg";
            [requestsQueue addRequest:uploadImage];

            //we start the request queue
            [requestsQueue start];
        }

        -(void) queueCompleted:(WRRequestQueue *)queue {
            //this will get called when all the requests are done
            //even if one or more requests end in error, this will still be called after the rest are completed
            NSLog(@"Done.");
        }

        -(void) requestCompleted:(WRRequest *) request{
            //called after 'request' is completed successfully
            NSLog(@"%@ completed!", request); 
        }

        -(void) requestFailed:(WRRequest *) request{
            //called after 'request' ends in error
            //we can print the error message
            NSLog(@"%@", request.error.message);
        }

        -(BOOL) shouldOverwriteFileWithRequest:(WRRequest *)request {
            //asks the delegate if it should overwrite a certain file
            //'request' is the request the intended to create the file that is already on server
            return YES;
        }
