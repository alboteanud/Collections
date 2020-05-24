import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth

class AddItemController: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: Properties
    
    var collection: Collection!
    private var user: User!
    private lazy var item: Item = Item(name: "", extraText: "", photoURL: Item.randomPhotoURL())
    var itemToEdit: Item?
    private var imagePicker = UIImagePickerController()
    private var downloadUrl: String?
    
    // MARK: Outlets
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var detailTextView: UITextView!
    @IBOutlet private weak var photoImageView: UIImageView!
    @IBOutlet fileprivate weak var addPhotoButton: UIButton!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var saveButton: UIBarButtonItem!
    
     // todo enable a Sign In button if no user
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = User(user: Auth.auth().currentUser!)
        hideKeyboardWhenTappedAround()
        
        // Handle the text field’s user input through delegate callbacks.
        nameTextField.delegate = self
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        
        // Set up views if editing an existing Item.
        if let item = itemToEdit {
            self.item = item
            navigationItem.title = "Edit"
            nameTextField.text = item.name
            detailTextView.text = item.extraText
            photoImageView.sd_setImage(with: item.photoURL)
        } else {
             navigationItem.title = "Add"
        }
        
        // Enable the Save button only if the text field has a valid Item name.
        updateSaveButtonState()
        
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
//        saveButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
//        navigationItem.title = textField.text
    }
    
    func saveChanges() {
        guard let extraText = detailTextView.text,
            let name = nameTextField.text, !name.isEmpty else {
                self.presentInvalidDataAlert(message: "Name must be filled out.")
                return
        }
        item.name = name
        item.extraText = extraText
        // if photo was changed, add the new url
        if let downloadUrl = downloadUrl {
            item.photoURL = URL(string: downloadUrl)!
        }
        print("Going to save document data as \(item.documentData)")
        let ref = Firestore.firestore().items(forCollection: collection.documentID)
            .document(item.documentID)
        ref.setData(item.documentData) { error in
            if let error = error {
                print("Error writing document: \(error)")
            } else {
                print("Write confirmed by the server")
            }
        }
//        self.presentDidSaveAlert()
        dismissViewController()
    }
    
    // MARK: IBActions
    
    @IBAction func didPressSave(_ sender: UIBarButtonItem) {
        saveChanges()
    }
    
    @IBAction func didPressSelectImageButton(_ sender: Any) {
        //        selectImage()
        showChooseSourceTypeAlertController()
    }
    
    // MARK: Navigation
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismissViewController()
    }
    
    func dismissViewController() {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
             let isPresentingInAddItemMode = presentingViewController is UINavigationController
             
             if isPresentingInAddItemMode {
                 dismiss(animated: true, completion: nil)
             }
             else if let owningNavigationController = navigationController{
                 owningNavigationController.popViewController(animated: true)
             }
             else {
                 fatalError("The ItemViewController is not inside a navigation controller.")
             }
    }
    
    // MARK: Alert Messages
    
    func presentDidSaveAlert() {
        let message = "Item added successfully!"
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
//            self.performSegue(withIdentifier: "unwindToCollectionItems", sender: self)
            self.dismissViewController()
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // If data in text fields isn't valid, give an alert
    func presentInvalidDataAlert(message: String) {
        Utils.showSimpleAlert(title: "Invalid Input", message: message, presentingVC: self)
    }
    
    func saveImage(photoData: Data) {
        loadingIndicator.isHidden = false
        let storagePath = "images/\(collection.documentID)/\(item.documentID)"
        let storageRef = Storage.storage().reference(withPath: storagePath)
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
    
    //MARK: Private Methods
    
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
}

extension AddItemController: UIImagePickerControllerDelegate {
    
    func showChooseSourceTypeAlertController() {
        let photoLibraryAction = UIAlertAction(title: "Choose a Photo", style: .default) { (action) in
            self.showImagePickerController(sourceType: .savedPhotosAlbum)
        }
        let cameraAction = UIAlertAction(title: "Take a New Photo", style: .default) { (action) in
            self.showImagePickerController(sourceType: .camera)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        var options = [photoLibraryAction, cancelAction]
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            options.append(cameraAction)
        }
        AlertService.showAlert(style: .actionSheet, title: nil, message: nil, actions: options, completion: nil)
    }
    
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType){
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = true
            imagePickerController.sourceType = sourceType
            present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage]
            as? UIImage,
            let photoData = editedImage.jpegData(compressionQuality: 0.9)
            //            let photoData = editedImage.resizeImage(1000.0, opaque: false).jpegData(compressionQuality: 0.8)
        {
            self.photoImageView.image = editedImage
            self.addPhotoButton.titleLabel?.text = ""
            self.addPhotoButton.backgroundColor = UIColor.clear
            saveImage(photoData: photoData)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

