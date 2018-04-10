//
//  AppDelegate.swift
//  ScrollPagingController
//
//  Created by Alexander Goremykin on 08.04.2018.
//  Copyright © 2018 Alexander Goremykin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()

        window.rootViewController = ViewController(nibName: nil, bundle: nil)
        window.makeKeyAndVisible()

        self.window = window

        return true
    }

}
