//
//  SYAppDelegate.m
//  TorrentAdder
//
//  Created by rominet on 19/05/14.
//  Copyright (c) 2014 Syan. All rights reserved.
//

#import "SYAppDelegate.h"
#import "NSString+Equal.h"

NSString *const UIAppDidOpenURL = @"kUIAppDidOpenURL";
NSString *const NSTorrentAddedSuccessfully = @"kNSTorrentAddedSuccessfully";

@implementation SYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.url = nil;
    self.appUrlIsFromParsed = SYAppUnknown;
    self.appUrlIsFrom = nil;
    
#ifdef DEBUG
    int64_t t = (int64_t)(2.0 * NSEC_PER_SEC);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, t), dispatch_get_main_queue(), ^{
        if(self.url)
            return;
        
        self.url = [NSURL URLWithString:@"magnet:?xt=urn:btih:4D753474429D817B80FF9E0C441CA660EC5D2450&dn=ubuntu+14+04+lts+desktop+64bit+iso&tr=udp%3A%2F%2Ftracker.publicbt.com%3A80%2Fannounce&tr=udp%3A%2F%2Fopen.demonii.com%3A1337"];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIAppDidOpenURL object:nil];
    });
#endif
    
    return YES;
}
							
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    self.url = url;
    self.appUrlIsFromParsed = SYAppUnknown;
    self.appUrlIsFrom = sourceApplication;
    
    if([sourceApplication isEqualToStringNoCase:@"com.apple.mobilesafari"])
        self.appUrlIsFromParsed = SYAppSafari;
    if([sourceApplication isEqualToStringNoCase:@"com.apple.mobilemail"])
        self.appUrlIsFromParsed = SYAppMail;
    if([sourceApplication isEqualToStringNoCase:@"com.apple.mobilesms"])
        self.appUrlIsFromParsed = SYAppSMS;
    if([sourceApplication isEqualToStringNoCase:@"com.google.chrome.ios"])
        self.appUrlIsFromParsed = SYAppChrome;
    if([sourceApplication isEqualToStringNoCase:@"com.dolphin.browser.iphone"])
        self.appUrlIsFromParsed = SYAppDolphin;
    if([sourceApplication isEqualToStringNoCase:@"com.opera.OperaMini"])
        self.appUrlIsFromParsed = SYAppOpera;
    if([sourceApplication isEqualToStringNoCase:@"com.orchestra.v2"])
        self.appUrlIsFromParsed = SYAppMailbox;
    
    
    
    if(self.appUrlIsFromParsed == SYAppUnknown) {
        NSLog(@"Launched from unknown app: %@",sourceApplication);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIAppDidOpenURL object:nil];
    
    return YES;
}

-(void)openAppThatOpenedMe
{
    NSString *selfClosingWebpage = @"rawgit.com/dvkch/TorrentAdder/master/self_closing_page.html";
    NSString *urlToOpen = nil;
    switch (self.appUrlIsFromParsed) {
        case SYAppSafari:   urlToOpen = @"https://";      break; // opens new page
        case SYAppMail:     urlToOpen = @"mailto:";       break; // opens empty composer
        case SYAppSMS:      urlToOpen = @"sms:";          break; // opens empty composer
        case SYAppChrome:   urlToOpen = @"googlechrome:"; break; // OK
        case SYAppDolphin:  urlToOpen = @"dolphin:";      break; // OK
        case SYAppOpera:    urlToOpen = @"ohttps://";     break; // opens new page
        case SYAppMailbox:  urlToOpen = @"dbx-mailbox:";  break; // OK
        default: break;
    }
    
    if(self.appUrlIsFromParsed == SYAppSafari ||
       self.appUrlIsFromParsed == SYAppOpera)
        urlToOpen = [urlToOpen stringByAppendingString:selfClosingWebpage];
    
    NSURL *url = [NSURL URLWithString:urlToOpen];
    [[UIApplication sharedApplication] openURL:url];
}


@end
