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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
