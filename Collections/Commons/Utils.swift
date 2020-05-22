import UIKit

class Utils: NSObject {

  static func showSimpleAlert(message: String, presentingVC: UIViewController) {
    Utils.showSimpleAlert(title: nil, message: message, presentingVC: presentingVC)
  }

  static func showSimpleAlert(title: String?, message: String, presentingVC: UIViewController) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default)
    alertController.addAction(okAction)
    presentingVC.present(alertController, animated: true, completion: nil)
  }

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
