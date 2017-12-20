//
//  CityTVCell.swift
//  PSPramatiTask
//
//  Created by Pankaj Sharma on 20/Dec/17.
//  Copyright © 2017 Pankaj Sharma. All rights reserved.
//

import UIKit

class CityTVCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var populationLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
    // Initialization code
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
  }
  
  override var textLabel: UILabel? {
    return titleLabel
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  func update(with city: CityEntity, highlightText: String? = nil) {
    if let highlightText = highlightText {
      self.titleLabel.attributedText = attributedText(with: city.title, highlightedPart: highlightText, font: UIFont.systemFont(ofSize: 17))
    } else {
      titleLabel?.text = city.title
    }
    populationLabel.text = "\(city.population)"    
  }
  
  private func attributedText(with string: String, highlightedPart: String, font: UIFont) -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: string,
                                                     attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.darkGray])
    let boldFontAttribute = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: font.pointSize),
        NSAttributedStringKey.foregroundColor: UIColor.black]
    let range = (string as NSString).range(of: highlightedPart, options: NSString.CompareOptions.caseInsensitive)
    attributedString.addAttributes(boldFontAttribute, range: range)
    return attributedString
  }

  
}
