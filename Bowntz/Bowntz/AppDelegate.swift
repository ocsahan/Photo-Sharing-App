//
//  AppDelegate.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/11/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var launchFromTerminated = true

    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "UserModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 1. Print out error if PNs registration not successful
        print("Failed to register for remote notifications with error: \(error)")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Request time once a day
        UIApplication.shared.setMinimumBackgroundFetchInterval(21600)
        application.registerForRemoteNotifications()
        //CloudUtility.shared.registerForSubscriptions()
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            return
        }
        
        // Check if the app has launched before, determine which storyboard to go to
        var storyboardName: String?
        if hasLaunchedBefore() {
            storyboardName = "Main"
        }
        else {
            storyboardName = "Welcome"
        }
        
        // Launch the appropriate controller, depending on whether the app has launched before
        let storyboard = UIStoryboard(name: storyboardName!, bundle: nil)
        let vc = storyboard.instantiateInitialViewController()
        self.window?.rootViewController = vc
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        showSplashScreen()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        let defaults = UserDefaults.standard
        let defaultDeveloper = ["developer_name": "Omer Cagri Sahan"]
        defaults.register(defaults: defaultDeveloper)
        defaults.synchronize()
        
        
        if launchFromTerminated {
            if !(topController() is NotificationViewController) {
                showSplashScreen()
            }
            launchFromTerminated = false
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    // Fetch method to get a random bowntz multiple times a day
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Get ID of a random bowntz to be scheduled
        CloudUtility.shared.getRandomBowntzID() { recordID in
            CloudUtility.shared.scheduleBowntz(recordID: recordID, completion: {
                print("Scheduled notification")
                completionHandler(.newData)
            })
        }
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void){
        print("Silent notification fired")
        let notification: CKNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        
        if (notification.notificationType == CKNotificationType.query) {
            let queryNotification = notification as! CKQueryNotification
            let recordID = queryNotification.recordID
            if let recordID = recordID {
                var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
                backgroundTaskIdentifier = application.beginBackgroundTask(expirationHandler: {
                    print("Couldn't get time to get metadata")
                    application.endBackgroundTask(backgroundTaskIdentifier!) })
                // Schedule notification to be shown in the future or now, depending on sender
                CloudUtility.shared.scheduleBowntz(recordID: recordID) {
                    completionHandler(.newData)
                    application.endBackgroundTask(backgroundTaskIdentifier!)
                }
            }
            else { print("No data in silent notification"); completionHandler(.noData) }
        }
    }}

extension AppDelegate {
    
    // Determine if the app has launched before
    func hasLaunchedBefore() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.value(forKey: "HAS_LAUNCHED_BEFORE") != nil {
            return true
        } else { return false }
    }
    
    // Load the SplashViewController from Splash.storyboard
    func showSplashScreen() {
        let storyboard = UIStoryboard(name: "Splash", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "SplashViewController") as! SplashViewController
        
        // Present the view controller over the top view controller
        let vc = topController()
        vc.present(controller, animated: false, completion: nil)
    }
    
    // Returns the top view controller
    func topController(_ parent: UIViewController? = nil) -> UIViewController {
        if let vc = parent {
            if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
                return topController(selected)
            } else if let nav = vc as? UINavigationController, let top = nav.topViewController {
                return topController(top)
            } else if let presented = vc.presentedViewController {
                return topController(presented)
            } else {
                return vc
            }
        } else {
            return topController(UIApplication.shared.keyWindow!.rootViewController!)
        }
    }
    
    func getRandomBowntzData() -> Data? {
        // Get contents of images directory
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storageDirectoryURL = documentDirectory.appendingPathComponent("images")
        let contents = try! FileManager.default.contentsOfDirectory(atPath: storageDirectoryURL.path)
        
        // Select a random item
        let randomIndex = Int(arc4random_uniform(UInt32(contents.count)))
        let file = contents[randomIndex]
        let fileURL = storageDirectoryURL.appendingPathComponent(file)
        
        print("Will schedule Bowntz for file in \(fileURL.description)")
        
        // Decode the item
        do {
            let bowntzData = try Data(contentsOf: fileURL)
            return bowntzData
        }
        catch { return nil }
    }
    
    func launchFromNotification(withBowntz bowntz: Bowntz) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "NotificationViewController") as! NotificationViewController

        controller.bowntz = bowntz
        let topVC = topController()
        if topVC is SplashViewController {
            print("splashviewcontroller")
            topVC.dismiss(animated: false, completion: { [unowned self] in
                self.window?.rootViewController?.present(controller, animated: true, completion: nil)
            })
        }
        else {
            topVC.present(controller, animated: false, completion: nil)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,  willPresent notification: UNNotification, withCompletionHandler   completionHandler: @escaping (_ options:   UNNotificationPresentationOptions) -> Void) {
        
        //Called when a notification is delivered to a foreground app.
        
        let userInfo = notification.request.content.userInfo as NSDictionary
        let recordName = userInfo["recordName"] as! String
        
        CloudUtility.shared.fetchSingleRecordByName(recordName: recordName) { (bowntz) in
            print("Launching from notification")
            self.launchFromNotification(withBowntz: bowntz)
            completionHandler([.alert])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Called to let your app know which action was selected by the user for a given notification.
        let userInfo = response.notification.request.content.userInfo as NSDictionary
        let recordName = userInfo["recordName"] as! String
        
        CloudUtility.shared.fetchSingleRecordByName(recordName: recordName) { (bowntz) in
            print("Launching from notification")
            DispatchQueue.main.sync {
                self.launchFromNotification(withBowntz: bowntz)
            }
            completionHandler()
        }
    }
}
