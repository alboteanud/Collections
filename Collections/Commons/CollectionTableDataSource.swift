
import UIKit
import FirebaseFirestore

/// A class that populates a table view using CollectionTableViewCell cells
/// with collection data from a Firestore query. Consumers should update the
/// table view with new data from Firestore in the updateHandler closure.
@objc class CollectionTableDataSource: NSObject, UITableViewDataSource {

    private let collections: LocalCollection<Collection>
    var sectionTitle: String?
    
    /// Returns an instance of CollectionTableViewDataSource. Consumers should update the
     /// table view with new data from Firestore in the updateHandler closure.
     public init(collections: LocalCollection<Collection>) {
       self.collections = collections
    
     }
    

    /// Returns an instance of CollectionTableViewDataSource. Consumers should update the
    /// table view with new data from Firestore in the updateHandler closure.
    public convenience init(query: Query, updateHandler: @escaping ([DocumentChange]) -> ()) {
      let collection = LocalCollection<Collection>(query: query, updateHandler: updateHandler)
      self.init(collections: collection)
    }

    /// Starts listening to the Firestore query and invoking the updateHandler.
    public func startUpdates() {
      collections.listen()
    }

    /// Stops listening to the Firestore query. updateHandler will not be called unless startListening
    /// is called again.
    public func stopUpdates() {
      collections.stopListening()
    }

    /// Returns the restaurant at the given index.
    subscript(index: Int) -> Collection {
      return collections[index]
    }

    /// The number of items in the data source.
    public var count: Int {
      return collections.count
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return sectionTitle
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath) as! CollectionCell
      let collection = collections[indexPath.row]
      cell.populate(collection: collection)
      return cell
    }
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            let collection = collections[indexPath.row]
//            print("deleting collection named: \(collection.name)")
//            deleteCollection(collectionID: collection.documentID)
//        }else if editingStyle == .insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//            print("insert selected")
//        }
//    }
    
//    func deleteCollection(collectionID: String){
//        Firestore.firestore().aCollection(forCollection: collectionID).delete() { error in
//            if let error = error {
//                print("Error deleting document: \(error)")
//            } else {
//                print("Delete confirmed by the server")
//            }
//        }
//    }
    
}
