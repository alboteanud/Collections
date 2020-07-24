
import UIKit
import FirebaseFirestore

/// A class that populates a table view using RestaurantTableViewCell cells
/// with restaurant data from a Firestore query. Consumers should update the
/// table view with new data from Firestore in the updateHandler closure.
@objc class ItemTableDataSource: NSObject, UITableViewDataSource {

  private let items: LocalCollection<Item>
    

  /// Returns an instance of RestaurantTableViewDataSource. Consumers should update the
  /// table view with new data from Firestore in the updateHandler closure.
  public init(items: LocalCollection<Item>) {
    self.items = items
    
  }

  /// Returns an instance of RestaurantTableViewDataSource. Consumers should update the
  /// table view with new data from Firestore in the updateHandler closure.
  public convenience init(query: Query, updateHandler: @escaping ([DocumentChange]) -> ()) {
    let collection = LocalCollection<Item>(query: query, updateHandler: updateHandler)
    self.init(items: collection)
  }

  /// Starts listening to the Firestore query and invoking the updateHandler.
  public func startUpdates() {
    items.listen()
  }

  /// Stops listening to the Firestore query. updateHandler will not be called unless startListening
  /// is called again.
  public func stopUpdates() {
    items.stopListening()
  }

  /// Returns the restaurant at the given index.
  subscript(index: Int) -> Item {
    return items[index]
  }

  /// The number of items in the data source.
  public var count: Int {
    return items.count
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell",
                                             for: indexPath) as! ItemCell
    let item = items[indexPath.row]
    cell.populate(item: item)
    return cell
  }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = items[indexPath.row]
            print("deleting item named: \(item.name)")
            deleteItem(itemID: item.documentID)
        }else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            print("insert selected")
        }
    }
    
    func deleteItem(itemID: String){
        let collectionRef = items.query as! CollectionReference
        collectionRef.document(itemID).delete() { error in
            if let error = error {
                print("Error deleting document: \(error)")
            } else {
                print("Delete confirmed by the server")
            }
        }
    }
    

}


