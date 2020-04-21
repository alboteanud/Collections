import UIKit

class ItemTableViewCell: UITableViewCell {
    
    @IBOutlet private var thumbnailView: UIImageView!

    @IBOutlet private var nameLabel: UILabel!

    func populate(item: Item) {
      nameLabel.text = item.name
      thumbnailView.sd_setImage(with: item.photoURL)
    }

    override func prepareForReuse() {
      super.prepareForReuse()
      thumbnailView.sd_cancelCurrentImageLoad()
    }
    
}
