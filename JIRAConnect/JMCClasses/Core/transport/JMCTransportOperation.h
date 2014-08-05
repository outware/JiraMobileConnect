@interface JMCTransportOperation : NSOperation  
{
@private
    BOOL finished;
    BOOL executing;
    BOOL looping;
    NSInteger statusCode;
    NSMutableData *responseData;
    NSThread *requestThread;
    NSURLConnection *connection;
    NSURLRequest *request;
    UIBackgroundTaskIdentifier backgroundTask;
}

@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, weak) id delegate;

+ (JMCTransportOperation *)operationWithRequest:(NSURLRequest *)request delegate:(id)delegate;

@end
