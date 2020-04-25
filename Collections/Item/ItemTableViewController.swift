import UIKit
import FirebaseAuth
import FirebaseUI
import FirebaseFirestore
import SDWebImage

class ItemTableViewController: UIViewController, UITableViewDelegate{
    
    // MARK: Properties
    
    private var collection: Collection!
    private var user: User!
    fileprivate var dataSource: ItemTableViewDataSource!
    
    // MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil), collection: Collection) -> ItemTableViewController {
      let controller = storyboard.instantiateViewController(withIdentifier: "ItemTableViewController")
          as! ItemTableViewController
      controller.collection = collection
      return controller
    }
    
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
        self.title = self.collection.name
      }

      tableView.dataSource = dataSource
      dataSource.startUpdates()
      tableView.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      dataSource.stopUpdates()
    }

    
    @IBAction func didTapAddItemButton(_ sender: Any) {
        let controller = AddItemViewController.fromStoryboard(collection: collection)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func unwindToItemsWithSegue (_ unwindSegue: UIStoryboardSegue) { }
    
    
    @IBAction func didTapEditButton(_ sender: Any) {
        let controller = EditCollectionViewController.fromStoryboard(collection: collection)
        self.navigationController?.pushViewController(controller, animated: true)
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
        var item = dataSource[indexPath.row]
        item.collectionID = collection.documentID
        let controller = ItemDetailViewController.fromStoryboard(item: item)
       self.navigationController?.pushViewController(controller, animated: true)
     }
    
}
