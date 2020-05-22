import UIKit

class CollectionCell: UITableViewCell {
    
//    @IBOutlet private var thumbnailView: UIImageView!
//    @IBOutlet private var nameLabel: UILabel!


    func populate(collection: Collection) {
       textLabel!.text = collection.name
//      thumbnailView.sd_setImage(with: collection.photoURL)
    }

    override func prepareForReuse() {
      super.prepareForReuse()
//      thumbnailView.sd_cancelCurrentImageLoad()
    }
    
}
