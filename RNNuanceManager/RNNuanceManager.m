//
//  RNNuanceManager.m
//  testspeech
//
//  Created by Peter Banka on 3/8/16.
//  Copyright © 2016 Peter Banka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RNNuanceManager.h"
#import <SpeechKit/SpeechKit.h>

@interface RNNuanceManager () <SKTransactionDelegate> {
    SKSession* _skSession;
    SKTransaction *_skTransaction;
    
    SKSState _state;
    
    NSTimer *_volumePollTimer;
    
}
@end


// State Logic: IDLE -> LISTENING -> PROCESSING -> repeat
enum {
    SKSIdle = 1,
    SKSListening = 2,
    SKSProcessing = 3
};

@implementation RNNuanceManager

- (instancetype)initWithParams:(NSString*)SKSAppKey
                     serverUrl:(NSString *)SKSServerUrl
             completionHandler:(void (^)(int code, NSString *value))completionHandler
{
    self = [super init];
    if (self) {
        _SKSAppKey = SKSAppKey;
        _SKSServerUrl = SKSServerUrl;
        _recognitionType = SKTransactionSpeechTypeDictation;
        _completionHandler = completionHandler;
        
        /*
         _recognitionType = SKTransactionSpeechTypeDictation;
         _recognitionType = SKTransactionSpeechTypeSearch;
         _recognitionType = SKTransactionSpeechTypeTV;
         */
        _endpointer = SKTransactionEndOfSpeechDetectionShort;
        /*
         _endpointer = SKTransactionEndOfSpeechDetectionLong;
         _endpointer = SKTransactionEndOfSpeechDetectionShort;
         _endpointer = SKTransactionEndOfSpeechDetectionNone;
         */
        
        _language = @"eng-USA";
        _state = SKSIdle;
        _skTransaction = nil;
        
        // Create a session
        _skSession = [[SKSession alloc] initWithURL:[NSURL URLWithString:SKSServerUrl] appToken:SKSAppKey];
        
        if (!_skSession) {
            NSLog(@"ERROR: Failed to initialize SpeehKit session.");
        }
    }
    return self;
}

- (void)start {
    NSLog(@"==============> START");
    _skTransaction = [_skSession recognizeWithType:_recognitionType
                                         detection:_endpointer
                                          language:_language
                                          delegate:self];
}

- (void)stop {
    [_skTransaction stopRecording];  // Synchronous?
    _completionHandler(-1, @"CANCELLED");
    
}

- (void)cancel {
    [_skTransaction cancel];
}

- (void)transactionDidBeginRecording:(SKTransaction *)transaction
{
    _state = SKSListening;
    [self startPollingVolume];
}

- (void)transactionDidFinishRecording:(SKTransaction *)transaction
{
    _completionHandler(2, @"PROCESSING");
    _state = SKSProcessing;
    [self stopPollingVolume];
}

- (void)transaction:(SKTransaction *)transaction didReceiveRecognition:(SKRecognition *)recognition
{
    _completionHandler(1, recognition.text);
    _state = SKSIdle;
}

- (void)transaction:(SKTransaction *)transaction didReceiveServiceResponse:(NSDictionary *)response
{
    // Excessive logging
    NSString* msg = [NSString stringWithFormat:@"didReceiveServiceResponse: %@", response];
    NSLog(@"%@", msg);
}

- (void)transaction:(SKTransaction *)transaction didFinishWithSuggestion:(NSString *)suggestion
{
    // TODO: Not sure what this is for
    _state = SKSIdle;
}

- (void)transaction:(SKTransaction *)transaction didFailWithError:(NSError *)error suggestion:(NSString *)suggestion
{
    NSLog(@"didFailWithError: %@. %@", [error description], suggestion);
    _completionHandler(-2, [error description]);
    _state = SKSIdle;
}

# pragma mark - Volume level

- (void)startPollingVolume
{
    // Every 50 milliseconds we should update the volume meter in our UI.
    _volumePollTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                        target:self
                                                      selector:@selector(pollVolume)
                                                      userInfo:nil repeats:YES];
}

- (void) pollVolume {
    NSString *output = [NSString stringWithFormat:@"%f", [_skTransaction audioLevel]];
    _completionHandler(0, output);
}

- (void) stopPollingVolume {
    [_volumePollTimer invalidate];
    _volumePollTimer = nil;
}

@end