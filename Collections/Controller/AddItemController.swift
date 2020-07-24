import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth

class AddItemController: UIViewController, UINavigationControllerDelegate {
    
    var collection: Collection!
    var item: Item? = nil
    private var mode = ControllerMode.add
    private var imagePicker = UIImagePickerController()
    private var downloadUrl: String?
    private var photoStorageRef: StorageReference?
    
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var detailTextView: UITextView!
    @IBOutlet private weak var photoImageView: UIImageView!
    @IBOutlet private weak var addPhotoButton: UIButton!
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!
//    @IBOutlet private weak var saveButton: UIBarButtonItem!
    @IBOutlet private weak var toolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        if let item = item {
            mode = ControllerMode.edit
            showEditUI(item: item)
        }
    }
    
    deinit {
        deleteUnsavedPhoto()
    }
    
    // MARK: IBActions
    
    @IBAction func didTapDeleteButton(_ sender: Any) {
        showDeleteWarning (message: "Are you sure you want to delete this item ?") { shouldDelete in
            if shouldDelete {
                self.deleteItem()
                self.dismissViewController()
            }
        }
    }
    
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        guard let itemName = textField.text, !itemName.isEmpty else {
            showSimpleAlert(title: "Invalid input", message: "Item name must be filled out.")
            return
        }
        saveChanges(itemName: itemName)
        dismissViewController()
    }
    
    @IBAction func didTapCancelButton(_ sender: Any) {
        deleteUnsavedPhoto()
        self.dismissViewController()
    }
    
    @IBAction func didPressSelectImageButton(_ sender: Any) {
        showChooseSourceTypeAlertController()
    }
    
    //MARK: Private Methods
    
    func saveImage(photoData: Data) {
        
        guard let currentUser = Auth.auth().currentUser else {
//                   dismissViewController()
                   return
        }
        
        loadingIndicator.isHidden = false
        
        if item == nil {
            item = Item(name: "", extraText: "", photoURL: Item.randomPhotoURL())
        }
        
        // Create file metadata to update
        let metadata = StorageMetadata()
        metadata.customMetadata = ["owner" : currentUser.uid]
        
        let storagePath = "images/\(collection.documentID)/\(item!.documentID)"
        photoStorageRef = Storage.storage().reference(withPath: storagePath)
        photoStorageRef!.putData(photoData, metadata: metadata) { (metadata, error) in
            self.loadingIndicator.isHidden = true
            if let error = error {
                print(error)
                 // to do show error
                return
            }
            self.photoStorageRef!.downloadURL { (url, error) in
                if let error = error {
                    print(error)
                }
                if let url = url {
                    self.downloadUrl = url.absoluteString
                }
            }
        }
    }
    
    func deleteUnsavedPhoto(){
        // if photo was uploaded but not needed (not save)
        if let photoStorageRef = photoStorageRef  {
            photoStorageRef.delete { error in
            if let error = error {
              // Uh-oh, an error occurred!
            } else {
              // File deleted successfully
            }
          }
        }
    }
    
    func showEditUI(item: Item){
        navigationItem.title = "Edit"
        textField.text = item.name
        detailTextView.text = item.extraText
        photoImageView.sd_setImage(with: item.photoURL)
        toolbar.isHidden = false
    }
    
    func saveChanges(itemName: String) {
        var newItem = item ?? Item(name: "", extraText: "", photoURL: Item.randomPhotoURL())
      
        newItem.name = itemName
        newItem.extraText = detailTextView.text
        
        // if photo was changed, add the new url
        if let downloadUrl = downloadUrl {
            newItem.photoURL = URL(string: downloadUrl)!
            self.photoStorageRef = nil // we signal photo solved. Saved.
        }
        print("Going to save document data as \(newItem.documentData)")
        let ref = Firestore.firestore().items(forCollection: collection.documentID)
            .document(newItem.documentID)
        ref.setData(newItem.documentData) { error in
            if let error = error {
                print("Error writing document: \(error)")
            } else {
                print("Write confirmed by the server")
            }
        }
        //        self.presentDidSaveAlert()
    }
    
    func deleteItem(){
        if item == nil { return }
        let ref = Firestore.firestore().items(forCollection: collection.documentID)
            .document(item!.documentID)
        ref.delete() { error in
            if let error = error {
                print("Error deleting document: \(error)")
            } else {
                print("Delete confirmed by the server")
            }
        }
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


