//
//  AddCollectionViewController.swift
//  FriendlyEats
//
//  Created by Dan Alboteanu on 07/04/2020.
//  Copyright © 2020 Firebase. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth

class AddCollectionViewController: UIViewController
{
    
    // MARK: Properties

    private var user: User!
    private lazy var collection: Collection = {
      return Collection(ownerID: user.userID, name: "")
    }()
    
    // MARK: Outlets

    @IBOutlet weak var collectionNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = User(user: Auth.auth().currentUser!)
        hideKeyboardWhenTappedAround()
    }
    
    func saveChanges() {
      guard let name = collectionNameTextField.text else {
          self.presentInvalidDataAlert(message: "Name must be filled out.")
          return
      }
      collection.name = name
      print("Going to save document data as \(collection.documentData)")
      Firestore.firestore().collections.document(collection.documentID)
          .setData(collection.documentData) { error in
            if let error = error {
              print("Error writing document: \(error)")
            } else {
              print("Write confirmed by the server")
            }
      }
      self.presentDidSaveAlert()
    }
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil))
        -> AddCollectionViewController {
      let controller = storyboard.instantiateViewController(withIdentifier: "AddCollectionViewController")
        as! AddCollectionViewController
      return controller
    }
    
    // MARK: IBActions

 
    @IBAction func didPressSaveButton(_ sender: Any) {
        print("did press save")
        saveChanges()
    }
    
    // MARK: Alert Messages

    func presentDidSaveAlert() {
      let message = "Collection added successfully!"
      let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: "OK", style: .default) { action in
        self.performSegue(withIdentifier: "unwindToMyCollectionsSegue", sender: self)
      }
      alertController.addAction(okAction)
      self.present(alertController, animated: true, completion: nil)
    }

    // If data in text fields isn't valid, give an alert
    func presentInvalidDataAlert(message: String) {
      Utils.showSimpleAlert(title: "Invalid Input", message: message, presentingVC: self)
    }

    
}
