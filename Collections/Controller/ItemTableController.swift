import UIKit
import FirebaseAuth
//import FirebaseUI
import FirebaseFirestore
import SDWebImage

class ItemTableController: UIViewController, UITableViewDelegate {
    
    // MARK: Properties
    
    var collection: Collection!
    private var user: User!
    fileprivate var dataSource: ItemTableViewDataSource!
    
    // MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        
        user = User(user: Auth.auth().currentUser!)
        // These should all be nonnull. The user can be signed out by an event
        // outside of the app, like a password change, but we're ignoring that case
        // for simplicity. In a real-world app, you should dismiss this view controller
        // or present a login flow if the user is unexpectedly nil.
        
        let query = Firestore.firestore().items(forCollection: collection.documentID)
        dataSource = ItemTableViewDataSource(query: query) { (changes) in
            self.tableView.reloadData()
         
        }
        self.title = self.collection.name
        
        tableView.dataSource = dataSource
        dataSource.startUpdates()
        tableView.delegate = self
        navigationItem.setHidesBackButton(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource.stopUpdates()
    }
    
    @IBAction func didTapAddItemButton(_ sender: Any) {
//        let controller = ItemViewController.fromStoryboard(collection: collection)
//        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func didTapCollectionsButton(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func unwindToItemsWithSegue (_ unwindSegue: UIStoryboardSegue) {
        let saveSegueID = EditCollectionController.GlobalVariables.saveSegueID
        
        // check if we're comming back from EditCollectionViewController.
        // !! We just edited the collection.
        if unwindSegue.identifier == saveSegueID {
           let sourceViewController = unwindSegue.source as? EditCollectionController
            if let modifiedCollection = sourceViewController?.collection {
                collection = modifiedCollection
                self.title = collection.name
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        set {}
        get {
            return .lightContent
        }
    }
    
    deinit {
        dataSource.stopUpdates()
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        var item = dataSource[indexPath.row]
//        item.collectionID = collection.documentID
//        let controller = ItemDetailViewController.fromStoryboard(item: item)
//        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    //MARK: - Navigation


    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddItem":
            print("Adding a new collection.")
            let destination = segue.destination as? UINavigationController
            guard let itemViewController = destination?.topViewController as? AddItemController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            itemViewController.collection = collection
            
        case "ShowItem":
            guard let itemViewController = segue.destination as? AddItemController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedItemCell = sender as? ItemCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedItemCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedItem = dataSource?[indexPath.row]
            itemViewController.itemToEdit = selectedItem
            itemViewController.collection = collection
            
        case "EditCollection":
            guard let collectionViewController = segue.destination as? EditCollectionController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            collectionViewController.collection = collection
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }

    
}
