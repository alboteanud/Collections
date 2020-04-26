import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth

class ItemViewController: UIViewController, UINavigationControllerDelegate{
        
    // MARK: Properties
    
    private var collection: Collection!
    private var user: User!
    private lazy var item: Item = {
        return Item( name: "", extraText: "", photoURL: Item.randomPhotoURL())
    }()
    private var imagePicker = UIImagePickerController()
    private var downloadUrl: String?
    
    // MARK: Outlets
    
    @IBOutlet private weak var itemNameTextField: UITextField!
    @IBOutlet private weak var descriptionTextField: UITextField!
    @IBOutlet private weak var itemImageView: UIImageView!
    @IBOutlet fileprivate weak var addPhotoButton: UIButton!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),  collection: Collection)
        -> ItemViewController {
            let controller = storyboard.instantiateViewController(withIdentifier: "AddItemViewController")
                as! ItemViewController
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
            let name = itemNameTextField.text, !name.isEmpty else {
                self.presentInvalidDataAlert(message: "Name must be filled out.")
                return
        }
        item.name = name
        item.extraText = detail
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
//        selectImage()
        showChooseSourceTypeAlertController()
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
    
}

extension ItemViewController: UIImagePickerControllerDelegate {
    
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
        self.itemImageView.image = editedImage
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

extension UIImage {
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
           var width: CGFloat
           var height: CGFloat
           var newImage: UIImage

           let size = self.size
           let aspectRatio =  size.width/size.height

           switch contentMode {
               case .scaleAspectFit:
                   if aspectRatio > 1 {                            // Landscape image
                       width = dimension
                       height = dimension / aspectRatio
                   } else {                                        // Portrait image
                       height = dimension
                       width = dimension * aspectRatio
                   }

           default:
               fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
           }

           if #available(iOS 10.0, *) {
               let renderFormat = UIGraphicsImageRendererFormat.default()
               renderFormat.opaque = opaque
               let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
               newImage = renderer.image {
                   (context) in
                   self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
               }
           } else {
               UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
                   self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
                   newImage = UIGraphicsGetImageFromCurrentImageContext()!
               UIGraphicsEndImageContext()
           }

           return newImage
       }
   }
