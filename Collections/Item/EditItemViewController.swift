//
//  EditItemViewController.swift
//  FriendlyEats
//
//  Created by Dan Alboteanu on 17/04/2020.
//  Copyright © 2020 Firebase. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class EditItemViewController: UIViewController, UINavigationControllerDelegate{
    
    // MARK: Properties
    
    private var item: Item!
    private var imagePicker = UIImagePickerController()
    private var downloadUrl: String?
    
    // MARK: Outlets
    
    @IBOutlet private weak var itemImageView: UIImageView!
    @IBOutlet private weak var itemNameTextField: UITextField!
    @IBOutlet weak var itemDetailTextField: UITextField!
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),
                               item: Item) -> EditItemViewController {
        let controller = storyboard.instantiateViewController(withIdentifier: "EditItemViewController")
            as! EditItemViewController
        controller.item = item
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemImageView.contentMode = .scaleAspectFill
        itemImageView.clipsToBounds = true
        hideKeyboardWhenTappedAround2()
        if let _ = item {
            populateItemScene()
        }
    }
    
    // populate item with current data
    func populateItemScene() {
        itemNameTextField.text = item.name
        itemDetailTextField.text = item.extraText
        itemImageView.sd_setImage(with: item.photoURL)
    }
    
    func saveChanges() {
        guard let detail = itemDetailTextField.text,
            let name = itemNameTextField.text, !name.isEmpty else {
                self.presentInvalidDataAlert(message: "Name field must be filled out.")
                return
        }
        var data = [
            "name": name,
            "detail": detail
            ] as [String : Any]
        
        
        // if photo was changed, add the new url
        if let downloadUrl = downloadUrl {
            data["photoURL"] = downloadUrl
        }
        guard let collectionID = item.collectionID else {
            return
        }
        let ref = Firestore.firestore().items(forCollection: collectionID)
            .document(item.documentID)
        
        ref.updateData(data) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Edit confirmed by the server.")
            }
        }
        self.presentDidSaveAlert()
    }
    
    
    // MARK: Keyboard functionality
    
    @objc func inputToolbarDonePressed() {
        resignFirstResponder()
    }
    
    @objc func keyboardNextButton() {
        if itemNameTextField.isFirstResponder {
            itemDetailTextField.becomeFirstResponder()
        } else {
            resignFirstResponder()
        }
    }
    
    @objc func keyboardPreviousButton() {
        if itemDetailTextField.isFirstResponder {
            itemNameTextField.becomeFirstResponder()
        } else {
            resignFirstResponder()
        }
    }
    
    lazy var inputToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        var doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.inputToolbarDonePressed))
        var flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        var fixedSpaceButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        
        var nextButton  = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_keyboard_arrow_left"), style: .plain, target: self, action: #selector(self.keyboardPreviousButton))
        nextButton.width = 50.0
        var previousButton  = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_keyboard_arrow_right"), style: .plain, target: self, action: #selector(self.keyboardNextButton))
        
        toolbar.setItems([fixedSpaceButton, nextButton, fixedSpaceButton, previousButton, flexibleSpaceButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        
        return toolbar
    }()
    
    
    // MARK: Alert Messages
    
    func presentDidSaveAlert() {
        let message = "Successfully saved!"
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            self.performSegue(withIdentifier: "unwindToItemsSegue", sender: self)
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentWillSaveAlert() {
        let message = "Are you sure you want to save changes to this item?"
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
    
    func saveImage(photoData: Data) {
        loadingIndicator.isHidden = false
        let storageRef = Storage.storage().reference(withPath: item.documentID)
        storageRef.putData(photoData, metadata: nil) { (metadata, error) in
            if let error = error {
                print(error)
                return
            }
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print(error)
                }
                if let url = url {
                    self.downloadUrl = url.absoluteString
                }
                self.loadingIndicator.isHidden = true
            }
        }
    }
    
    // MARK: IBActions
    
    @IBAction func selectNewImage(_ sender: Any) {
        selectImage()
    }
    
    @IBAction func didSelectSaveChanges(_ sender: Any) {
        presentWillSaveAlert()
    }

    
}

extension EditItemViewController: UIImagePickerControllerDelegate {
    
    func selectImage() {
        imagePicker.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            imagePicker.sourceType = .savedPhotosAlbum;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let photo = info[UIImagePickerController.InfoKey.originalImage] as? UIImage, let photoData = photo.jpegData(compressionQuality: 0.8) {
            itemImageView.image = photo
            changePhotoButton.backgroundColor = UIColor.clear
            //             self.addPhotoButton.titleLabel?.text = ""
            saveImage(photoData: photoData)
            
        }
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension UIViewController {
    
    func hideKeyboardWhenTappedAround2() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard2))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard2() {
        view.endEditing(true)
    }
}
