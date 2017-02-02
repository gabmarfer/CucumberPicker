//
//  AlbumViewCell.swift
//  CucumberPicker
//
//  Created by gabmarfer on 27/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit

class AlbumViewCell: UITableViewCell {
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        commonInit()
    }
    
    private func commonInit() {
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
        nameLabel.text = nil
        countLabel.text = nil
    }
    
    override func layoutSubviews() {
        coverImageView.layer.cornerRadius = 4.0
        coverImageView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
