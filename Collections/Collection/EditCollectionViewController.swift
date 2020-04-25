//
//  EditCollectionViewController.swift
//  Collections
//
//  Created by Dan Alboteanu on 23/04/2020.
//  Copyright © 2020 Dan Alboteanu. All rights reserved.
//

import UIKit
import Firebase

class EditCollectionViewController: UIViewController {
    
    private var collection: Collection!
    @IBOutlet var collectionNameTextField: UITextField!
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),  collection: Collection)
        -> EditCollectionViewController {
            let controller = storyboard.instantiateViewController(withIdentifier: "EditCollectionViewController")
                as! EditCollectionViewController
            controller.collection = collection
            return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionNameTextField.text = collection.name
    }
    
    @IBAction func didTapSaveChangesButton(_ sender: Any) {
        presentWillSaveAlert()
    }
    
    @IBAction func didTapDeleteButton(_ sender: Any) {
        presentWillDeleteAlert()
    }
    
    
    func saveChanges() {
        guard let name = collectionNameTextField.text, !name.isEmpty
            else {
                self.presentInvalidDataAlert(message: "Name field must be filled out.")
                return
        }
        let data = ["name": name] as [String : Any]
        
        let ref = Firestore.firestore().collections.document(collection.documentID)
        
        ref.updateData(data) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Edit confirmed by the server.")
            }
        }
        self.title = name
        self.presentDidSaveAlert()
    }
    
    func deleteCollection()  {
        let refCollection = Firestore.firestore().collections.document(collection.documentID)
        refCollection.delete { (err) in
            if let err = err {
                print("Error deleting document collection: \(err)")
            } else {
                print("Delete document confirmed by the server.")
            }
        }
        // this will trigger a cloud function to delete all item documents in the collection
        
        self.title = ""
        self.presentDidDeleteAlert()
    }
    
    // MARK: Alert Messages
    
    func presentDidSaveAlert() {
        let message = "Successfully saved!"
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            self.performSegue(withIdentifier: "unwindToMyCollectionsSegue", sender: self)
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentDidDeleteAlert() {
        let message = "Successfully deleted!"
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            self.performSegue(withIdentifier: "unwindToMyCollectionsSegue", sender: self)
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
      
      func presentWillSaveAlert() {
          let message = "Are you sure you want to save changes to this collection?"
          let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
          let saveAction = UIAlertAction(title: "Save", style: .default) { action in
              self.saveChanges()
          }
          let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
          alertController.addAction(saveAction)
          alertController.addAction(cancelAction)
          
          self.present(alertController, animated: true, completion: nil)
      }
      
      // If data in text fields isn't valid, give an alert
      func presentInvalidDataAlert(message: String) {
          Utils.showSimpleAlert(title: "Invalid Input", message: message, presentingVC: self)
      }
    
    func presentWillDeleteAlert(){
        let message = "Are you sure you want to delete \"\(collection.name)\" collection?"
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                let deleteAction = UIAlertAction(title: "Delete", style: .default) { action in
                    self.deleteCollection()
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(deleteAction)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true, completion: nil)
    }
    

}
