import UIKit
import FirebaseAuth
import FirebaseUI

class Utils: NSObject {

  static func priceString(from price: Int) -> String {
    return (0 ..< price).reduce("") { s, _ in s + "$" }
  }

  static func priceValue(from string: String?) -> Int? {
    guard let string = string else { return nil }
    // TODO: Maybe ensure that we're only counting dollar signs
    return string.count
  }

}

extension String {
    func isBlankOrEmpty() -> Bool {

        // Check empty string
        if self.isEmpty {
            return true
        }
        // Trim and check empty string
        return (self.trimmingCharacters(in: .whitespaces) == "")
    }
}

extension UIViewController {
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    func presentLoginController() {
          guard let authUI = FUIAuth.defaultAuthUI() else { return }
          guard authUI.auth?.currentUser == nil else {
              print("Attempted to present auth flow while already logged in")
              return
          }
          
          FUIAuth.defaultAuthUI()?.tosurl = urlTermsOfService
          FUIAuth.defaultAuthUI()?.privacyPolicyURL = urlPrivacyPolicy
          
          authUI.providers = [
              FUIGoogleAuth(),
              FUIEmailAuth(),
              FUIOAuth.appleAuthProvider()
          ]
          
          let controller = authUI.authViewController()
          self.present(controller, animated: true, completion: nil)
      }
    
    func dismissViewController() {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
             let isPresentingInAddItemMode = presentingViewController is UINavigationController
             
             if isPresentingInAddItemMode {
                 dismiss(animated: true, completion: nil)
             }
             else if let owningNavigationController = navigationController{
                 owningNavigationController.popViewController(animated: true)
             }
             else {
                 fatalError("The ItemViewController is not inside a navigation controller.")
             }
    }
    

    func showSimpleAlert(title: String?, message: String) {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: "OK", style: .default)
      alertController.addAction(okAction)
      self.present(alertController, animated: true, completion: nil)
    }
    
    func showDeleteWarning(message: String, completion: @escaping (Bool)->()) {
        //Create the alert controller and actions
        let alert = UIAlertController(title: "Warning delete", message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            completion(true)
        }

        //Add the actions to the alert controller
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)

        //Present the alert controller
        present(alert, animated: true, completion: nil)
    }
    
}


let urlTermsOfService = URL(string: "https://sunshine-f15bf.firebaseapp.com/")!
let urlPrivacyPolicy = URL(string: "https://sunshine-f15bf.firebaseapp.com/")!
