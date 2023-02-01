//
//  AppDelegate.swift
//  Nerve-ous
//
//  Created by Nikol Nikolova on 17.06.21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        CoreData.subject.name = "DefaultName"
        if(UserDefaults.standard.bool(forKey: "notFirstInApp") == false){
            UserDefaults.standard.set(true, forKey: "notFirstInApp")
            //Here you can show a view that you have to launch at first launch
            let mainViewController = MMTFacialNerveHomeViewController(first: true)
            let mainNavigationController = MMTNavigationController(rootViewController: mainViewController)
            self.window!.rootViewController = mainNavigationController
            self.window!.makeKeyAndVisible()
            return true
        }else{
            //Here you can show a view that you have to launch after first launch
            let mainViewController = MMTFacialNerveHomeViewController(first: false)
            let mainNavigationController = MMTNavigationController(rootViewController: mainViewController)
            self.window!.rootViewController = mainNavigationController
            self.window!.makeKeyAndVisible()
            return true
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}

