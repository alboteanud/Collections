import UIKit
import FirebaseAuth
import FirebaseUI
import FirebaseFirestore
import SDWebImage

class CollectionTableController: UIViewController, UITableViewDelegate {
    
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
    
    fileprivate var dataSource: CollectionTableDataSource? = nil
    private var authListener: AuthStateDidChangeListenerHandle? = nil
    
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var profileImageView: UIImageView!
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private weak var signInButton: UIButton!
    @IBOutlet private weak var signOutButton: UIButton!
    @IBOutlet private var addCollectionButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableBackgroundLabel.text = "There aren't any collections here."
        tableView.backgroundView = tableBackgroundLabel
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUser(firebaseUser: Auth.auth().currentUser)
        Auth.auth().addStateDidChangeListener { (auth, newUser) in
            self.setUser(firebaseUser: newUser)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        dataSource?.stopUpdates()
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
    
    fileprivate func populate(user: User?) {
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
    
    fileprivate func populateCollections(forUser user: User) {
        let query = Firestore.firestore().collections.whereField("ownerID", isEqualTo: user.userID)
        dataSource = CollectionTableDataSource(query: query) { [unowned self] (changes) in
            self.tableView.reloadData()
            guard let dataSource = self.dataSource else { return }
            if dataSource.count > 0 {
                self.tableView.backgroundView = nil
            } else {
                self.tableView.backgroundView = self.tableBackgroundLabel
            }
        }
        //        dataSource?.sectionTitle = "My Collections"
        dataSource?.startUpdates()
        tableView.dataSource = dataSource
    }
    
    deinit {
        dataSource?.stopUpdates()
    }
    
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
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedCollectionCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedCollection = dataSource?[indexPath.row]
            itemTableViewController.collection = selectedCollection
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
//    @IBAction func unwindToCollections(_ unwindSegue: UIStoryboardSegue) { }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Edit", handler: {action,view,completionHandler in
            guard let collection = self.dataSource?[indexPath.row] else {return}
            let controller = AddCollectionController.fromStoryboard(collection: collection)
            self.navigationController?.pushViewController(controller, animated: true)
            completionHandler(true)
        })
        action.backgroundColor = .orange
        let config = UISwipeActionsConfiguration(actions: [action])
        return config
    }
    
}


