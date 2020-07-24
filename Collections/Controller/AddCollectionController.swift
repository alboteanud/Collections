import UIKit
import Firebase
import FirebaseAuth

class AddCollectionController: UIViewController {
    
    fileprivate var user: User? = nil {
        didSet {
            populate(user: user) }
    }
    
    var collection: Collection? = nil
    private var mode = ControllerMode.add
    @IBOutlet weak var textField: UITextField!
    @IBOutlet private var profileImageView: UIImageView!
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var signInView: UIView!
    @IBOutlet var toolbar: UIToolbar!
    var didChangeCollection: ((_ collection: Collection?) -> Void)?
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),
                               collection: Collection) -> AddCollectionController {
        let controller = storyboard.instantiateViewController(withIdentifier: "AddCollectionController") as! AddCollectionController
        controller.collection = collection
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentUser = Auth.auth().currentUser {
            user = User(user: currentUser)
        }
        if let collection = collection {
            mode = ControllerMode.edit
            showEditUI(collection: collection)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUser(firebaseUser: Auth.auth().currentUser)
        Auth.auth().addStateDidChangeListener { (auth, newUser) in
            self.setUser(firebaseUser: newUser)
        }
    }
    
    // MARK: IBActions
    
    @IBAction func didTapDeleteButton(_ sender: Any) {
        showDeleteWarning (message: "Are you sure you want to delete this collection ?") { shouldDelete in
            if shouldDelete {
                self.deleteCollection()
                self.didChangeCollection?(nil)
                self.dismissViewController()
            }
        }
    }
    
    @IBAction func didTapCancelButton(_ sender: Any) {
        self.dismissViewController()
    }
    
    @IBAction func didTapSignInButton(_ sender: Any) {
        presentLoginController()
    }
    
    @IBAction private func didTapSignOutButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch let error {
            print("Error signing out: \(error)")
        }
    }
    
    @IBAction func didTapSaveButton() {
        if (user == nil){
            showSimpleAlert(title: "Sign in required", message: "You must be signed in to save a collection.")
            return
        }
        guard let collectionName = textField.text, !collectionName.isEmpty else {
            showSimpleAlert(title: "Invalid input", message: "Collection name must be filled out.")
            return
        }
        saveChanges(collectionName: collectionName)
        self.dismissViewController()
    }
    
    //MARK: Private Methods
    
    fileprivate func setUser(firebaseUser: FirebaseAuth.UserInfo?) {
        if let firebaseUser = firebaseUser {
            let user = User(user: firebaseUser)
            self.user = user
            Firestore.firestore().users.document(user.userID).setData(user.documentData) { error in if let error = error {
                print("Error writing user to Firestore: \(error)")}
            }
        } else {
            user = nil
        }
    }
    
    func saveChanges(collectionName: String){
        var newCollection = collection ?? Collection(ownerID: user!.userID, name: "")
        
        newCollection.name = collectionName
        print("Going to save document data as \(newCollection.documentData)")
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let refCollectionDoc = db.aCollection(forCollection: newCollection.documentID)
        refCollectionDoc.setData(newCollection.documentData)
        
        let refCollectionItems = db.collectionItems(forCollection: newCollection.documentID)
        batch.setData(
            ["author": user!.name,
             "authorID": user!.userID,
             "createDate": Timestamp(date: Date())
        ], forDocument: refCollectionItems)
        
        if mode == ControllerMode.add {
            let refCollectionItemsUsers = db.collectionItems(forCollection: newCollection.documentID).collection("users").document(user!.userID)
            refCollectionItemsUsers.setData(["role" : "admin"])
        }
        
        batch.commit(){ error in
            if let error = error {
                print("Error writing batch: \(error)")
            } else {
                print("Write confirmed by the server")
                //                self.presentDidSaveAlert()
            }
        }
        didChangeCollection?(newCollection)
    }
    
    fileprivate func populate(user: User?) {
        if mode == ControllerMode.edit { return }
        
        if let user = user {
            profileImageView.sd_setImage(with: user.photoURL)
            usernameLabel.text = user.name
            signInButton.isHidden = true
            signOutButton.isHidden = false
        } else {
            profileImageView.image = UIImage(named: "placeholder")
            usernameLabel.text = "Sign in, why don'cha?"
            signInButton.isHidden = false
            signOutButton.isHidden = true
        }
    }
    
    func deleteCollection(){
        guard let collectionID = collection?.documentID else { return }
        Firestore.firestore().aCollection(forCollection: collectionID).delete() { error in
            if let error = error {
                print("Error deleting document: \(error)")
            } else {
                print("Delete confirmed by the server")
            }
        }
    }
    
    func showEditUI(collection: Collection){
        self.title = "Edit collection"
        textField.text = collection.name
        signInView.isHidden = true
        toolbar.isHidden = false
    }
    
}

enum ControllerMode {
    case add
    case edit
}




