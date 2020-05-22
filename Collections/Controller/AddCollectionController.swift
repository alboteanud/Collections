import UIKit
import Firebase
import FirebaseAuth

class AddCollectionController: UIViewController, UITextFieldDelegate {
    
    private var user: User? = nil
    private lazy var collection: Collection = { return Collection(ownerID: user!.userID, name: "") }()
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // todo enable a Sign In button if no user
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // we assume the user is signedIn
        user = User(user: Auth.auth().currentUser!)
        nameTextField.delegate = self
        
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
    
    // MARK: Navigation
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            print("The save button was not pressed, cancelling")
            return
        }
        saveChanges()
        
    }
    
    //MARK: Private Methods
    
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = user != nil && !text.isBlankOrEmpty()
    }
    
    func saveChanges() {
        if (user == nil){
            return
        }
        collection.name = nameTextField.text ?? "_"
        print("Going to save document data as \(collection.documentData)")
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let refCollectionDoc = db.aCollection(forCollection: collection.documentID)
        refCollectionDoc.setData(collection.documentData)
        
        // todo - use cloud functions to do this
        let refCollectionItems = db.collectionItems(forCollection: collection.documentID)
        batch.setData(
            ["author": user!.name,
             "authorID": user!.userID,
             "createDate": Timestamp(date: Date())
        ], forDocument: refCollectionItems)
        
        let refCollectionItemsUsers = db.collectionItems(forCollection: collection.documentID).collection("users").document(user!.userID)
        refCollectionItemsUsers.setData(["role" : "admin"])
        
        batch.commit(){ error in
            if let error = error {
                print("Error writing batch: \(error)")
            } else {
                print("Write confirmed by the server")
            }
        }
    }
    
}


