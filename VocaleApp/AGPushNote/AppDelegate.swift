//
//  AppDelegate.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/27.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    static var layerClient: LYRClient?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Event.registerSubclass()
        EventResponse.registerSubclass()
        Parse.enableLocalDatastore()
        Parse.setApplicationId("mHwgC5UeSRQruIM5Yy0lvDyjqGS2Dj4NjO31JzBE", clientKey: "95guXp3SXxvryiBxMloDjrjvofstKlmq11bneCcZ")
        PFUser.enableAutomaticUser()

        if application.applicationState != UIApplicationState.Background {
            let preBackgroundPush = !application.respondsToSelector(Selector("backgroundRefreshStatus"))
            let oldPushHandlerOnly = !self.respondsToSelector(#selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        if application.respondsToSelector(#selector(UIApplication.registerForRemoteNotifications)) {
            let userNotificationTypes = UIUserNotificationType.Alert.union(UIUserNotificationType.Badge).union(UIUserNotificationType.Sound).union(UIUserNotificationType.Alert)
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            let types = UIRemoteNotificationType.Badge.union(UIRemoteNotificationType.Alert).union(UIRemoteNotificationType.Sound)
            application.registerForRemoteNotificationTypes(types)
            application.registerForRemoteNotifications()
        }

        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        PFFacebookUtils.initializeFacebook()
        UITabBar.appearance().selectedImageTintColor = UIColor.vocaleRedColor()

        PFUser.currentUser()?.fetchIfNeededInBackgroundWithBlock({ (user: PFObject?, error: NSError?) -> Void in
            if let user = user, let userIDString = user.objectId {

                let appID = NSURL(string: "layer:///apps/staging/45f026f2-a10f-11e5-8f8b-4e4f000000ac")
                AppDelegate.layerClient = LYRClient(appID: appID!)

                AppDelegate.layerClient?.connectWithCompletion({ (success: Bool, error: NSError?) -> Void in
                    if (!success) {
                        print("LAYER CONNECT FAILED")
                    } else {

                        self.authenticateLayerWithUserID(userIDString, completion: { (success, error) -> Void in
                            if !success {
                                print("ERROR")
                            }
                        })

                    }
                })
            }
        })

        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.lightTextColor(), NSFontAttributeName: UIFont(name: "Raleway-SemiBold", size: 19)!]
        UINavigationBar.appearance().barTintColor = UIColor.vocaleHeaderBackgroundGreyColor()
        UINavigationBar.appearance().tintColor = UIColor.lightGrayColor()
        UIToolbar.appearance().barTintColor = UIColor.vocaleHeaderBackgroundGreyColor()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics: .Default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "Back Arrow")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "Back Arrow")

        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.vocaleLightGreyColor(), NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 16)!], forState: .Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 16)!], forState: .Disabled)
        UITextField.appearance().font = UIFont(name: "Raleway-Regular", size: 16)
        UITabBar.appearance().tintColor = UIColor.whiteColor()

        ATLConversationTableViewCell.appearance().backgroundColor = UIColor.clearColor()
        ATLConversationTableViewCell.appearance().contentView.backgroundColor = UIColor.clearColor()

        if let shortcutItem =
            launchOptions?[UIApplicationLaunchOptionsShortcutItemKey]
                as? UIApplicationShortcutItem {

                    handleQuickAction(shortcutItem)
                    return false
        }

        return true
    }

    static var quickSearchActionWasSelected = false

    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {

        print("Handle quick actions")
        completionHandler(handleQuickAction(shortcutItem))

    }

    enum Shortcut: String {
        case search = "Search"
    }

    func handleQuickAction(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var quickActionHandled = false
        let type = shortcutItem.type.componentsSeparatedByString(".").last!
        if let shortcutType = Shortcut.init(rawValue: type) {
            switch shortcutType {
            case .search:
                AppDelegate.quickSearchActionWasSelected = true
                NSNotificationCenter.defaultCenter().postNotificationName("QuickActionSearchTapped", object: nil)
                quickActionHandled = true
            }
        }
        return quickActionHandled
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        FBAppCall.handleDidBecomeActiveWithSession(PFFacebookUtils.session())
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        PFFacebookUtils.session()?.close()
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication, withSession: PFFacebookUtils.session())
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()

        do {
            try AppDelegate.layerClient?.updateRemoteNotificationDeviceToken(deviceToken)
        } catch {
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: \(error)")
        }
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if application.applicationState == UIApplicationState.Active {
            if let controller = self.window?.rootViewController as? ConversationViewController {
            } else {
                var alertMessage = ""
                if let aps = userInfo["aps"] as? [NSObject: AnyObject] {
                    if let alert = aps["alert"] as? String {
                        alertMessage = alert
                    }
                }
                AGPushNoteView.showWithNotificationMessage(alertMessage)
            }
        } else {
            PFPush.handlePush(userInfo)
        }
        if application.applicationState == UIApplicationState.Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }
    }


    // MARK: - Layer Authentication Methods
    func authenticateLayerWithUserID(userID: String, completion :(success: Bool, error: NSError?) -> Void) {
        if let authenticatedUserID = AppDelegate.layerClient!.authenticatedUserID {
            completion(success:true, error:nil)
        } else {
            AppDelegate.layerClient!.requestAuthenticationNonceWithCompletion({(nonce, error) in
                if let nonce = nonce {
                    print("nonce \(nonce)")

                    if let user = PFUser.currentUser(), let userId = user.objectId {
                        PFCloud.callFunctionInBackground("generateToken", withParameters: ["nonce": nonce, "userID":userId], block: { (token: AnyObject?, error: NSError?) -> Void in
                            if let token = token as? NSString {
                                AppDelegate.layerClient?.authenticateWithIdentityToken(String(token), completion: { (string: String?, error: NSError?) -> Void in

                                })
                            }
                        })
                    }

                } else {
                    completion(success:false, error:error)
                }
            })
        }
        return
    }


    func authenticationTokenWithUserId(userID: String, completion :(success: Bool?, error: NSError?) -> Void) {
        AppDelegate.layerClient?.requestAuthenticationNonceWithCompletion({ (nonce: String?, error: NSError?) -> Void in
            if nonce == nil {
                completion(success: false, error: error)
                return
            }
            if let nonce = nonce {
                if let user = PFUser.currentUser(), let userId = user.objectId {
                    PFCloud.callFunctionInBackground("generateToken", withParameters: ["nonce": nonce, "userID":userId], block: { (token: AnyObject?, error: NSError?) -> Void in
                        if let token = token as? NSString {
                            AppDelegate.layerClient?.authenticateWithIdentityToken(String(token), completion: { (string: String?, error: NSError?) -> Void in

                            })
                        }
                    })
                }
            }
        })
    }

}
