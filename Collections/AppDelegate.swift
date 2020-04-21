import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  
        FirebaseApp.configure()
        
        // Globally set our navigation bar style
        let navigationStyles = UINavigationBar.appearance()
        navigationStyles.barTintColor =
          UIColor(red: 0x3d/0xff, green: 0x5a/0xff, blue: 0xfe/0xff, alpha: 1.0)
        navigationStyles.tintColor = UIColor(white: 0.8, alpha: 1.0)
            navigationStyles.titleTextAttributes = [ NSAttributedString.Key.foregroundColor: UIColor.white]
        
        return true
    }

}

