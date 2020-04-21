
import UIKit
import FirebaseFirestore

/// A class that populates a table view using RestaurantTableViewCell cells
/// with restaurant data from a Firestore query. Consumers should update the
/// table view with new data from Firestore in the updateHandler closure.
@objc class ItemsTableViewDataSource: NSObject, UITableViewDataSource {

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
                                             for: indexPath) as! ItemTableViewCell
    let item = items[indexPath.row]
    cell.populate(item: item)
    return cell
  }

}


