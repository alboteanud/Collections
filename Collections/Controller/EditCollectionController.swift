import UIKit
import Firebase
import FirebaseAuth

class EditCollectionController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties

    private var user: User!
    var collection: Collection!
    
    // MARK: Outlets

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // we assume the user is signedIn
        user = User(user: Auth.auth().currentUser!)
//        hideKeyboardWhenTappedAround()
        nameTextField.delegate = self
        
        if let _ = collection {
            nameTextField.text = collection.name
        }
        
        // Enable the Save button only if the text field has a valid Collection name.
        updateSaveButtonState()    
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        saveButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
    }
    
//    func saveChanges() {
//        guard let name = nameTextField.text, !name.isEmpty
//        else {
//          self.presentInvalidDataAlert(message: "Name must be filled out.")
//          return
//      }
//        collection.name = name
//        print("Going to save document data as \(collection.documentData)")
//        let ref = Firestore.firestore().collections
//            .document(collection.documentID)
//        ref.setData(collection.documentData) { error in
//            if let error = error {
//                print("Error writing document: \(error)")
//            } else {
//                print("Write confirmed by the server")
//            }
//      }
////      self.presentDidSaveAlert()
//    }
    
    func saveChanges2() {
          collection.name = nameTextField.text ?? "_"
          print("Going to save document data as \(collection.documentData)")
          let db = Firestore.firestore()
          let batch = db.batch()
          
          let refCollectionDoc = db.aCollection(forCollection: collection.documentID)
          refCollectionDoc.setData(collection.documentData)
          
          batch.commit(){ error in
              if let error = error {
                  print("Error writing batch: \(error)")
              } else {
                  print("Write confirmed by the server")
              }
          }
      }
    
    // MARK: IBActions

    @IBAction func didPressSaveButton(_ sender: Any) {
        saveChanges2()
        self.performSegue(withIdentifier: GlobalVariables.saveSegueID, sender: self)
    }
    
    //MARK: Private Methods
    
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isBlankOrEmpty()
    }
    
    // MARK: Alert Messages

//    func presentDidSaveAlert() {
//      let message = "Collection added successfully!"
//      let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//      let okAction = UIAlertAction(title: "OK", style: .default) { action in
//        self.performSegue(withIdentifier: GlobalVariables.saveSegueID, sender: self)
//      }
//      alertController.addAction(okAction)
//      self.present(alertController, animated: true, completion: nil)
//    }
//    
//    
//
//    // If data in text fields isn't valid, give an alert
//    func presentInvalidDataAlert(message: String) {
//      Utils.showSimpleAlert(title: "Invalid Input", message: message, presentingVC: self)
//    }
    
    struct GlobalVariables{
        static let saveSegueID = "unwindToCollectionItemsFromSaveSegue"
    }

    
}
