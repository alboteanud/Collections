import UIKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage

class ItemTableController: UIViewController {
    
    fileprivate var dataSource: ItemTableDataSource!
    @IBOutlet weak var tableView: UITableView!
    var collection: Collection!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        
        guard Auth.auth().currentUser != nil else {
            dismissViewController()
            return
        }
        configureView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource.stopUpdates()
    }
    
    deinit {
        dataSource.stopUpdates()
    }
    
    func configureView() {
        title = collection.name
        let query = Firestore.firestore().items(forCollection: collection.documentID)
        dataSource = ItemTableDataSource(query: query) { (changes) in
            self.tableView.reloadData()
        }
        tableView.dataSource = dataSource
        dataSource.startUpdates()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddItem":
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
            itemViewController.item = selectedItem
            itemViewController.collection = collection
            
        case "AddCollection":
            // edit collection
            let destination = segue.destination as? UINavigationController
            guard let collectionViewController = destination?.topViewController as? AddCollectionController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            collectionViewController.didChangeCollection = { newCollection in
                if newCollection == nil {
                    // colection was deleted
                    self.dismissViewController()
                } else {
                    self.title = newCollection!.name
                    self.collection = newCollection
                }
            }
            collectionViewController.collection = collection
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
//    @IBAction func unwindToItems(for unwindSegue: UIStoryboardSegue) { }

}
