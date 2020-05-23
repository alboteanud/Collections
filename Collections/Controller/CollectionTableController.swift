import UIKit
import FirebaseAuth
import FirebaseUI
import FirebaseFirestore
import SDWebImage

let urlTermsOfService = URL(string: "https://sunshine-f15bf.firebaseapp.com/")!
let urlPrivacyPolicy = URL(string: "https://sunshine-f15bf.firebaseapp.com/")!

class CollectionTableController: UITableViewController {
    
    /// The current user displayed by the controller. Setting this property has side effects.
    fileprivate var user: User? = nil {
        didSet {
            populate(user: user)
            if let user = user {
                populateCollections(forUser: user)
            } else {
                dataSource?.stopUpdates()
                dataSource = nil
                tableView.backgroundView = tableBackgroundLabel
                tableView.reloadData()
            }
        }
    }
    
    lazy private var tableBackgroundLabel: UILabel = {
        let label = UILabel(frame: tableView.frame)
        label.textAlignment = .center
        return label
    }()
    
    fileprivate var dataSource: CollectionTableViewDataSource? = nil
    private var authListener: AuthStateDidChangeListenerHandle? = nil
    
//    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var profileImageView: UIImageView!
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet var addCollectionButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableBackgroundLabel.text = "There aren't any collections here."
        tableView.backgroundView = tableBackgroundLabel
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUser(firebaseUser: Auth.auth().currentUser)
        Auth.auth().addStateDidChangeListener { (auth, newUser) in
            self.setUser(firebaseUser: newUser)
        }
                      tableView.delegate = self
    }
    
    @IBAction func didTapSignInButton(_ sender: Any) {
        presentLoginController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    fileprivate func setUser(firebaseUser: FirebaseAuth.UserInfo?) {
        if let firebaseUser = firebaseUser {
            let user = User(user: firebaseUser)
            self.user = user
            Firestore.firestore().users.document(user.userID).setData(user.documentData) { error in if let error = error {  print("Error writing user to Firestore: \(error)")}
            }
        } else {
            user = nil
        }
    }
    
    fileprivate func populate(user: User?) {
        if let user = user {
            profileImageView.sd_setImage(with: user.photoURL)
            usernameLabel.text = user.name
            signInButton.isHidden = true
            signOutButton.isHidden = false
            addCollectionButton.isEnabled = true
        } else {
            profileImageView.image = UIImage(named: "placeholder")
            usernameLabel.text = "Sign in, why don'cha?"
            signInButton.isHidden = false
            signOutButton.isHidden = true
            addCollectionButton.isEnabled = false
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    fileprivate func populateCollections(forUser user: User) {
        let query = Firestore.firestore().collections.whereField("ownerID", isEqualTo: user.userID)
        dataSource = CollectionTableViewDataSource(query: query) { [unowned self] (changes) in
            self.tableView.reloadData()
            guard let dataSource = self.dataSource else { return }
            if dataSource.count > 0 {
                self.tableView.backgroundView = nil
            } else {
                self.tableView.backgroundView = self.tableBackgroundLabel
            }
        }
        dataSource?.sectionTitle = "My Collections"
        dataSource?.startUpdates()
        tableView.dataSource = dataSource
    }
    
    fileprivate func presentLoginController() {
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
    
    @IBAction private func didTapSignOutButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch let error {
            print("Error signing out: \(error)")
        }
    }
    
    //    @IBAction func unwindToMyCollections(segue: UIStoryboardSegue) {}
    
    //MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddCollection":
            print("Adding a new collection.")
            
        case "ShowCollection":
            guard let itemTableViewController = segue.destination as? ItemTableController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedCollectionCell = sender as? CollectionCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedCollectionCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedCollection = dataSource?[indexPath.row]
            itemTableViewController.collection = selectedCollection
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    @IBAction func unwindToCollections(_ unwindSegue: UIStoryboardSegue) {
//        let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
}

// MARK: - UITableViewDelegate

//   extension CollectionTableViewController: UITableViewDelegate {
//
//     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//       tableView.deselectRow(at: indexPath, animated: true)
////        guard let collection = dataSource?[indexPath.row] else { return }
////       let controller = ItemTableViewController.fromStoryboard(collection: collection)
////       self.navigationController?.pushViewController(controller, animated: true)
//     }
//}

