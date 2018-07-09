//
//  FB_Plugin.h
//  Bolts
//
//  Created by Mac on 7/9/18.
//

#import <Foundation/Foundation.h>

typedef void (^FBCompletion)(NSString * responseString, id object, int errorCode, NSString *description, NSError * error);

@interface FB_Plugin : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

+ (FB_Plugin*)shareInstance;

- (void)applicationDidBecomeActive:(UIApplication *)application;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

- (void)signoutFacebook;
- (void)startLoginFacebookWithCompletion:(FBCompletion)completion;

- (void)didShareFacebook:(NSDictionary*)dict andCompletion:(FBCompletion)completion;

- (void)startLoginTwitterWithCompletion:(FBCompletion)completion;

- (void)application_Twitter:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (BOOL)application_Twitter:(NSURL *)url;

@property (nonatomic, retain) NSString * facebookAppID;

@property (nonatomic, retain) NSString * twitterConsumerSecret;

@property (nonatomic, retain) NSString * twitterConsumerKey;

@property (nonatomic, retain) NSString * twitterUrlScheme;

@end
