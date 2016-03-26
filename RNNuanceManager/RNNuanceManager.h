//
//  RNNuanceManager.h
//  testspeech
//
//  Created by Peter Banka on 3/8/16.
//  Copyright © 2016 Peter Banka. All rights reserved.
//

#import <SpeechKit/SKTransaction.h>
#import <SpeechKit/SpeechKit.h>
#import <AVFoundation/AVFoundation.h>


#ifndef RNNuanceManager_h
#define RNNuanceManager_h


typedef NSUInteger SKSState;


@interface RNNuanceManager : NSObject <SKTransactionDelegate>

@property (strong, nonatomic) NSString *SKSAppKey;
@property (strong, nonatomic) NSString *SKSServerUrl;
@property (strong, nonatomic) NSString *language;
@property (strong, nonatomic) NSString *recognitionType;
@property (assign, nonatomic) SKTransactionEndOfSpeechDetection endpointer;
@property (nonatomic) SKSState state;
@property (nonatomic, strong) void (^completionHandler)(int, NSString*);


- (instancetype)initWithParams:(NSString*)SKSAppKey
                     serverUrl:(NSString*)SKServerUrl
             completionHandler:(void (^)(int result, NSString *value))completionHandler;
- (void)start;
- (void)stop;
- (void)cancel;

@end

#endif /* RNNuanceManager_h */
