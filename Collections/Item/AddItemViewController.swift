import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth

class AddItemViewController: UIViewController, UINavigationControllerDelegate{
        
    // MARK: Properties
    
    private var collection: Collection!
    private var user: User!
    private lazy var item: Item = {
        return Item( name: "", detail: "", photoURL: Item.randomPhotoURL())
    }()
    private var imagePicker = UIImagePickerController()
    private var downloadUrl: String?
    
    // MARK: Outlets
    
    @IBOutlet private weak var itemNameTextField: UITextField!
    @IBOutlet private weak var descriptionTextField: UITextField!
    @IBOutlet private weak var itemImageView: UIImageView!
    @IBOutlet fileprivate weak var addPhotoButton: UIButton!
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),  collection: Collection)
        -> AddItemViewController {
            let controller = storyboard.instantiateViewController(withIdentifier: "AddItemViewController")
                as! AddItemViewController
            controller.collection = collection
            return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = User(user: Auth.auth().currentUser!)
        itemImageView.contentMode = .scaleAspectFill
        itemImageView.clipsToBounds = true
        hideKeyboardWhenTappedAround()
    }
    
    func saveChanges() {
        guard let detail = descriptionTextField.text,
            let name = itemNameTextField.text else {
                self.presentInvalidDataAlert(message: "Name must be filled out.")
                return
        }
        item.name = name
        item.detail = detail
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
        self.presentDidSaveAlert()
    }
    
    // MARK: IBActions

    @IBAction func didPressSave(_ sender: UIBarButtonItem) {
        print("did press save")
        saveChanges()
    }
    
    @IBAction func didPressSelectImageButton(_ sender: Any) {
        selectImage()
    }

    // MARK: Alert Messages
    
    func presentDidSaveAlert() {
        let message = "Item added successfully!"
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            self.performSegue(withIdentifier: "unwindToItemsSegue", sender: self)
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // If data in text fields isn't valid, give an alert
    func presentInvalidDataAlert(message: String) {
        Utils.showSimpleAlert(title: "Invalid Input", message: message, presentingVC: self)
    }
    
    func saveImage(photoData: Data) {
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
        }
      }
    }
    
}

extension AddItemViewController: UIImagePickerControllerDelegate {
    
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
        self.itemImageView.image = photo
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
