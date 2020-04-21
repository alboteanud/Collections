import UIKit

class CollectionTableViewCell: UITableViewCell {
    
//    @IBOutlet private var thumbnailView: UIImageView!

    @IBOutlet private var nameLabel: UILabel!


    func populate(collection: Collection) {
      nameLabel.text = collection.name
//      thumbnailView.sd_setImage(with: collection.photoURL)
    }

    override func prepareForReuse() {
      super.prepareForReuse()
//      thumbnailView.sd_cancelCurrentImageLoad()
    }
    
}
