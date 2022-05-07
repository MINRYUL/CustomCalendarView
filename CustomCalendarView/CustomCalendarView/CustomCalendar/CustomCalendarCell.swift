//
//  CustomCalendarCell.swift
//  CustomCalendarView
//
//  Created by 김민창 on 2022/05/03.
//

import UIKit

class CustomCalendarCell: UICollectionViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dayFooterView: UIView!
    
    static let identifier = "CustomCalendarCell"
    
    static private let _nibName: UINib = UINib(nibName: CustomCalendarCell.identifier, bundle: .main)
    
    static func register(to collectionView: UICollectionView) {
        collectionView.register(
            _nibName,
            forCellWithReuseIdentifier: CustomCalendarCell.identifier
        )
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self._configureView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self._configureView()
    }
    
    override func prepareForReuse() {
        self.dayLabel.font = .systemFont(ofSize: 15, weight: .regular)
        self.dayLabel.alpha = 1.0
        self.dayFooterView.isHidden = true
        self.backgroundColor = .clear
        self.dayLabel.textColor = .label
        self.dayFooterView.backgroundColor = .label
    }
    
    private func _configureView() {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = false
        self.clipsToBounds = true
    }
    
    func display(cellModel: CustomCalendarCellModel) {
        self.dayLabel.text = "\(cellModel.day)"
        
        if !cellModel.isCurrentMonth {
            self.dayLabel.alpha = 0.3
        } else {
            self.dayLabel.alpha = 1.0
        }
        
        if cellModel.isCurrentDay {
            self.dayFooterView.isHidden = false
            self.dayLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        }
        
        if cellModel.isSelected {
            self.backgroundColor = .systemBlue
            self.dayLabel.alpha = 1.0
            self.dayLabel.textColor = .white
        }
    }
}
