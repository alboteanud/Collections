import UIKit
import SDWebImage
import FirebaseFirestore
import Firebase
import FirebaseUI

class ItemDetailViewController: UIViewController {
    
    private var item: Item!
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil), item: Item) -> ItemDetailViewController {
       let controller = storyboard.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
       controller.item = item
       return controller
     }
    
    @IBOutlet weak var titleUIView: ItemTitleView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var bottomToolbar: UIToolbar!

    @IBOutlet weak var detailLabel: UILabel!
    
//    let backgroundView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = item.name
        detailLabel.text = item.extraText
    }

    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
//      localCollection.listen()
        titleUIView.populate(item: item)
    }
    
    // MARK: @IBActions
    
    @IBAction func didTapEditButton(_ sender: Any) {
      let controller = EditItemViewController.fromStoryboard(item: item)
      self.navigationController?.pushViewController(controller, animated: true)
    }
    
  
@IBAction func unwindToItemDetail(segue: UIStoryboardSegue) {}
    
  
}

class ItemTitleView: UIView {
  
//  @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView! {
    didSet {
      let gradient = CAGradientLayer()
      gradient.colors =
          [UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor, UIColor.clear.cgColor]
      gradient.locations = [0.0, 1.0]
      
      gradient.startPoint = CGPoint(x: 0, y: 1)
      gradient.endPoint = CGPoint(x: 0, y: 0)
      gradient.frame = CGRect(x: 0,
                              y: 0,
                              width: UIScreen.main.bounds.width,
                              height: imageView.bounds.height)
      
      imageView.layer.insertSublayer(gradient, at: 0)
      imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
    }
  }
  
  func populate(item: Item) {
//    nameLabel.text = item.name
    imageView.sd_setImage(with: item.photoURL)
  }
  
}
