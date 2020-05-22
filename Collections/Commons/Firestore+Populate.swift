import FirebaseFirestore

extension Firestore {

  /// Returns a reference to the top-level users collection.
  var users: CollectionReference {
    return self.collection("users")
  }
    
    /// Returns a reference to the top-level collections collection.
    var collections: CollectionReference {
      return self.collection("collections")
    }
    
    func aCollection(forCollection collectionID: String) -> DocumentReference {
        return self.collection("collections").document(collectionID)
       }
    
    func collectionItems(forCollection collectionID: String) -> DocumentReference {
           return self.collection("collectionItems").document(collectionID)
          }
    
    /// Returns a reference to the top-level items collection.
     var collectionItems: CollectionReference {
       return self.collection("collectionItems")
     }

    /// Returns a reference to the items collection for a specific collection.
    func items(forCollection collectionID: String) -> CollectionReference {
      return self.collection("collectionItems/\(collectionID)/items")
    }
    
}

// MARK: Write operations

extension Firestore {
    
    /// Writes a user to the top-level users collection, overwriting data if the
    /// user's uid already exists in the collection.
    func add(user: User) {
        self.users.document(user.documentID).setData(user.documentData)
    }
    
    /// Writes an item to the yums subcollection for a specific review.
    func add(item: Item, forCollection collectionID: String) {
        self.items(forCollection: collectionID).document(item.documentID).setData(item.documentData)
    }
    
}

extension WriteBatch {
    
    /// Writes a user to the top-level users collection, overwriting data if the
    /// user's uid already exists in the collection.
    func add(user: User) {
        let document = Firestore.firestore().users.document(user.documentID)
        self.setData(user.documentData, forDocument: document)
    }
    
    /// Writes an item to the collection
    func add(item: Item, toCollection: String) {
        let document = Firestore.firestore().items(forCollection: toCollection).document(item.documentID)
        self.setData(item.documentData, forDocument: document)
    }
    
}
