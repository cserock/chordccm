//
//  AppDelegate.m
//  codex
//
//  Created by Rock Kang on 2014. 5. 11..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import "AppDelegate.h"
#import "FMDB.h"
#import "RootViewController.h"
#import "HomeViewController.h"
#import "iRate.h"
#import "GAI.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#define DATABASE_NAME @"codex.rdb"
#define NSLog //

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"me.neosave.chordccm";
	[iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    [iRate sharedInstance].daysUntilPrompt = 3;
    [iRate sharedInstance].usesUntilPrompt = 10;
    
    
    //enable preview mode
//    [iRate sharedInstance].previewMode = YES;
    
    [self initializeDatabase];
    
    // Optional: automatically send uncaught exceptions to Google Analytics.
//    [GAI sharedInstance].trackUncaughtExceptions = NO;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
//    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
//    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker. Replace with your tracking ID.
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-52996345-1"];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                  openURL:url
                                                        sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                               annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
                    ];
    // Add any custom logic here.
    return handled;
}

- (NSString*)getChordPitchString:(NSString*) chordPitch {
    
    NSString *returnChordPitchString = nil;
    
    if([chordPitch isEqualToString:@"+"]){
        returnChordPitchString = @"♯";
    } else if([chordPitch isEqualToString:@"-"]){
        returnChordPitchString = @"♭";
    } else {
        returnChordPitchString = @"";
    }
    return returnChordPitchString;
}

-(void) initializeDatabase
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:DATABASE_NAME];
    
    // if the path does not exist, then we need to initialize the database.
    if ([fileManager fileExistsAtPath:path] == NO)
    {
        
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DATABASE_NAME];
        NSError *error;
        
        BOOL success = [fileManager copyItemAtPath:defaultDBPath toPath:path error:&error];

        if (!success) {
            NSLog(@"Failed to create writable DB. Error '%@'.", [error localizedDescription]);
        } else {
            NSLog(@"successfully created database");
            
            NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            
            [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"db_version"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    else {
        // check to see if we have attempted to upgrade the database before.
        // we only want to run the ALTER command once after an upgrade.
        NSString *dbVersion = [[NSUserDefaults standardUserDefaults]
                               stringForKey:@"db_version"];
        
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        NSLog(@"check db version : appVersion : %@ / dbVersion : %@", appVersion, dbVersion);
        
        if (![dbVersion isEqualToString:appVersion]) {
            
            NSLog(@"process to update database.");
            
            NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DATABASE_NAME];
            NSError *error;
            
            BOOL success = [fileManager removeItemAtPath:path error:&error];
            
            if (!success) {
                NSLog(@"Failed to remove DB. Error '%@'.", [error localizedDescription]);
            } else {
                success = [fileManager copyItemAtPath:defaultDBPath toPath:path error:&error];
                
                if (!success) {
                    NSLog(@"Failed to create writable DB. Error '%@'.", [error localizedDescription]);
                } else {
                    NSLog(@"successfully updated database");
                    
                    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
                    [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"db_version"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            
        } else {
            NSLog(@"no issue to update database.");
        }
    }
}

- (BOOL) isPad {
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 30200)
    if ([[UIDevice currentDevice] respondsToSelector: @selector(userInterfaceIdiom)])
        return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
#endif
    return NO;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
