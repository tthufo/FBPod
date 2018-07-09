//
//  FB_Plugin.m
//  Bolts
//
//  Created by Mac on 7/9/18.
//

#import "FB_Plugin.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

#import <CommonCrypto/CommonHMAC.h>

#import "NSData+Base64.h"

#import "SVProgressHUD.h"

#define version @"1.0"

#define signatureMethod @"HMAC-SHA1"

static FB_Plugin * instance = nil;

@interface FB_Plugin ()<FBSDKSharingDelegate>
{
    NSString * non, * sign, * token, * stamp;
}
@end

@implementation FB_Plugin
{
    FBCompletion completionBlock;
}

@synthesize twitterConsumerKey, twitterConsumerSecret, twitterUrlScheme, facebookAppID;

+ (FB_Plugin*)shareInstance
{
    if(!instance)
    {
        instance = [FB_Plugin new];
    }
    return instance;
}

- (void)startLoginFacebookWithCompletion:(FBCompletion)completion
{
    [FBSDKSettings setAppID:self.facebookAppID];
    self->completionBlock = completion;
    if ([FBSDKAccessToken currentAccessToken])
    {
        [self requestFacebookInformation];
    }
    else
    {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        
        [login logInWithReadPermissions:@[] fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            
            if (error)
            {
                self->completionBlock(nil, nil, -1, error.localizedDescription, error);
            }
            else if (result.isCancelled)
            {
                self->completionBlock(nil, nil, -1, error.localizedDescription, nil);
            }
            else
            {
                [self requestFacebookInformation];
            }
        }];
    }
}

- (void)showLoading
{
    [SVProgressHUD showWithStatus:@"Đang tải"];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeCustom];
    [SVProgressHUD setBackgroundColor:[UIColor orangeColor]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
}

- (NSString *)convertPercentage:(NSString*)input
{
    NSString *convert = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                              (CFStringRef)input,
                                                                                              NULL,
                                                                                              (CFStringRef)@"!*'();:@&+$,/?%#[]",
                                                                                              kCFStringEncodingUTF8 ));
    return convert;
}

- (NSMutableDictionary*)reFormat:(NSDictionary*)input
{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithDictionary:input];
    
    for(NSString * key in dict.allKeys)
    {
        if([dict[key] isKindOfClass:[NSDictionary class]])
        {
            dict[key] = [self reFormat:((NSDictionary*)dict[key])];
        }
        else
        {
            if(dict[key] == [NSNull null])
            {
                dict[key] = @"";
            }
        }
    }
    return dict;
}

- (void)requestFacebookInformation
{
    [self showLoading];
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, email"}]
     
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
         if (error)
         {
             [SVProgressHUD dismiss];
             
             self->completionBlock(nil, nil, -1, error.localizedDescription, error);
             
             return;
         }
         [self didRequestAvatarWithInfo:result];
     }];
}

- (void)didRequestAvatarWithInfo:(NSDictionary *)dict
{
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:[NSString stringWithFormat:@"me/?fields=picture.width(720).height(720),id,name"]
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error)
     {
         if (!error)
         {
             NSMutableDictionary * data = [self reFormat:dict];
             
             NSLog(@"%@", result);
             
             data[@"avatar"] = result[@"picture"][@"data"][@"url"];
             
             self->completionBlock(@"ok",@{@"info":data} , 0, nil, error);
         }
         else
         {
             self->completionBlock(nil, nil, -1, @"errormessage", error);
         }
         
         [SVProgressHUD dismiss];
     }];
}

- (void)signoutFacebook
{
    if ([FBSDKAccessToken currentAccessToken])
    {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logOut];
    }
    instance = nil;
}

- (void)didShareFacebook:(NSDictionary*)dict andCompletion:(FBCompletion)completion
{
    completionBlock = completion;
    
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:dict[@"content"]];
    
    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
    dialog.delegate = self;
    dialog.fromViewController = dict[@"host"];
    dialog.shareContent = content;
    dialog.mode = FBSDKShareDialogModeAutomatic;
    [dialog show];
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    completionBlock(nil, error, -1, error.localizedDescription, error);
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    completionBlock(nil, results, 1, nil, nil);
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    completionBlock(nil, nil, -1, nil, nil);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBSDKAppEvents activateApp];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if(!dictionary)
    {
        NSLog(@"Check your Info.plist is not right path or name");
    }
    
    if (!dictionary[@"FacebookAppID"])
    {
        NSLog(@"Please setup FacebookAppID in Plist");
    }
    else
    {
        self.facebookAppID = dictionary[@"FacebookAppID"];
    }
    if (!dictionary[@"FacebookDisplayName"])
    {
        NSLog(@"Please setup FacebookDisplayName in Plist");
    }
    if (dictionary[@"FacebookAppID"])
    {
        BOOL found = NO;
        NSString *appID = [NSString stringWithFormat:@"fb%@", dictionary[@"FacebookAppID"]];
        if (dictionary[@"CFBundleURLTypes"])
        {
            for (NSDictionary *item in dictionary[@"CFBundleURLTypes"])
            {
                if (item[@"CFBundleURLSchemes"])
                {
                    for (NSString *scheme in item[@"CFBundleURLSchemes"])
                    {
                        if ([scheme isEqualToString:appID])
                        {
                            found = YES;
                            break;
                        }
                    }
                }
            }
        }
        if (!found)
        {
            NSLog(@"Please setup URL types in Plist as %@", appID);
        }
    }
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}


- (void)startLoginTwitterWithCompletion:(FBCompletion)completion
{
    if(!self.twitterUrlScheme || !self.twitterConsumerKey || !self.twitterConsumerSecret)
    {
        NSLog(@"Please check for credential keys in pList");
        
        return ;
    }
    
    completionBlock = completion;
    
    NSString *callback = [self convertPercentage:self.twitterUrlScheme];
    
    NSString *callback1 = [[callback description] stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
    
    NSString *string = @"abcdefghijklmnopqrstuvwxyz0123456789";
    
    NSMutableString * nonce = [NSMutableString stringWithCapacity:string.length];
    
    for (int i=0; i<string.length; i++)
    {
        [nonce appendFormat: @"%c", [string characterAtIndex: arc4random() % string.length]];
    }
    
    non = nonce;
    
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    
    NSString *timeStamp = [NSString stringWithFormat:@"%d",(int)time];
    
    NSString *baseURL = @"https://api.twitter.com/oauth/request_token";
    
    NSString *result0 = [self convertPercentage:baseURL];
    
    
    NSString *signature=
    [NSString stringWithFormat:@"oauth_callback=%@&oauth_consumer_key=%@&oauth_nonce=%@&oauth_signature_method=%@&oauth_timestamp=%@&oauth_version=%@"
     , callback1, self.twitterConsumerKey, nonce, signatureMethod, timeStamp, version];  // ----> success
    
    stamp = timeStamp;
    
    NSString *result=[signature description];
    result=[result stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
    result=[result stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    result=[result stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    result=[result stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    
    NSString *textData=[NSString stringWithFormat:@"POST&%@&%@",result0,result];
    
    NSString *keyData=[NSString stringWithFormat:@"%@&",self.twitterConsumerSecret];
    
    NSData *textt=[textData dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *keyy=[keyData dataUsingEncoding:NSUTF8StringEncoding];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
    CCHmacContext hmacContext;
    CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyy.bytes, keyy.length);
    CCHmacUpdate(&hmacContext, textt.bytes, textt.length);
    CCHmacFinal(&hmacContext, digest);
    NSData * out = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
    NSString *s= [out base64EncodedString];
    
    NSString * chuKy = [[NSString alloc]init];
    chuKy=[s description];
    chuKy=[chuKy stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
    chuKy=[chuKy stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    chuKy=[chuKy stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    chuKy=[chuKy stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    chuKy=[chuKy stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    
    sign = chuKy;
    
    NSURL *URL=[NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    
    NSString *request1=[NSString stringWithFormat:@"OAuth oauth_callback=\"%@\", oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_signature=\"%@\", oauth_signature_method=\"%@\",oauth_timestamp=\"%@\", oauth_version=\"1.0\"", callback, self.twitterConsumerKey, nonce, chuKy, signatureMethod, timeStamp];
    
    NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:URL];
    
    [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest setValue:@"OAuth gem v0.4.4" forHTTPHeaderField:@"User-Agent"];
    
    [urlRequest setValue:@"api.twitter.com" forHTTPHeaderField:@"Host"];
    
    [urlRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    
    
    [urlRequest setValue:request1 forHTTPHeaderField:@"Authorization"];
    
    
    NSString *returnString = [[NSString alloc] initWithData:
                              [NSURLConnection sendSynchronousRequest:urlRequest
                                                    returningResponse:nil error:nil]encoding:NSUTF8StringEncoding];
    
    if([returnString isEqualToString:@""])
    {
        self->completionBlock(nil, nil, -1, @"errormessage", nil);
    }
    
    NSString * _token;
    NSScanner *scanner = [NSScanner scannerWithString:returnString];
    [scanner scanUpToString:@"o" intoString:NULL];
    [scanner scanUpToString:@"&" intoString:&_token];
    
    NSLog(@"--->%@",returnString);
    
    token = _token;
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?%@",_token]]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?%@",_token]]];
}


- (void)application_Twitter:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if(!dictionary)
    {
        NSLog(@"Check your Info.plist is not right path or name");
    }
    
    if (!dictionary[@"twitterConsumerKey"])
    {
        NSLog(@"Please setup twitterConsumerKey in Plist");
    }
    else
    {
        self.twitterConsumerKey = dictionary[@"twitterConsumerKey"];
    }
    
    if (!dictionary[@"twitterConsumerSecret"])
    {
        NSLog(@"Please setup twitterConsumerSecret in Plist");
    }
    else
    {
        self.twitterConsumerSecret = dictionary[@"twitterConsumerSecret"];
    }
    
    if (!dictionary[@"twitterUrlScheme"])
    {
        NSLog(@"Please setup twitterUrlScheme in Plist");
    }
    else
    {
        self.twitterUrlScheme = dictionary[@"twitterUrlScheme"];
    }
}

- (BOOL)application_Twitter:(NSURL *)url
{
    NSString *url1=[url absoluteString];
    
    if(![url1 containsString:@"oauth_verifier"])
    {
        return YES;
    }
    
    NSString*verifier = nil;
    NSScanner *scanner1 = [NSScanner scannerWithString:url1];
    [scanner1 scanUpToString:@"&" intoString:NULL];
    [scanner1 scanUpToString:@" " intoString:&verifier];
    
    NSString*status2 =  [verifier substringFromIndex:1] ;
    
    NSString *token1 = [token substringFromIndex:12];
    
    NSURL *URL=[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    
    NSString *request2=[NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_signature=\"%@\", oauth_signature_method=\"%@\",oauth_timestamp=\"%@\", oauth_token=\"%@\", oauth_version=\"1.0\"", self.twitterConsumerKey, non, sign, signatureMethod, stamp, token1];
    
    NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:URL];
    
    [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest setValue:@"OAuth gem v0.4.4" forHTTPHeaderField:@"User-Agent"];
    
    [urlRequest setValue:@"api.twitter.com" forHTTPHeaderField:@"Host"];
    
    [urlRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setValue:request2 forHTTPHeaderField:@"Authorization"];
    
    [urlRequest setHTTPBody:[status2 dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *returnString = [[NSString alloc] initWithData:
                              [NSURLConnection sendSynchronousRequest:urlRequest
                                                    returningResponse:nil error:nil]encoding:NSUTF8StringEncoding];
    NSLog(@"--->%@",returnString);
    
    NSArray * key = @[@"token", @"tokenSecret", @"userId", @"screenName", @"expire"];
    
    NSMutableDictionary * dict = [NSMutableDictionary new];
    
    for(NSString * s in [returnString componentsSeparatedByString:@"&"])
    {
        dict[key[[[returnString componentsSeparatedByString:@"&"] indexOfObject:s]]] = [[s componentsSeparatedByString:@"="] lastObject];
    }
    
    completionBlock(@"ok",dict , 0, nil, nil);
    
    return YES;
}

@end
