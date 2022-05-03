//
//  CustomCalendarView.swift
//  CustomCalendarView
//
//  Created by 김민창 on 2022/05/03.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

protocol CustomCalenderViewDelegate: AnyObject {
    func didSelectedDate(date: Date)
}

@IBDesignable
final class CustomCalendarView: UIView {
    private let xibName = "CustomCalendar"
    
    @IBOutlet weak var yearMonthLabel: UILabel!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var calendarHeightConstraints: NSLayoutConstraint!
    
    weak var delegate: CustomCalenderViewDelegate?
    
    var disposeBag: DisposeBag = DisposeBag()
    
    var viewModel = CustomCalendarViewModel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    private func configure(){
        guard let view = Bundle
            .main
            .loadNibNamed(xibName, owner: self, options: nil)?
            .first as? UIView else { return }
        view.frame = self.bounds
        self.addSubview(view)
        
        self._configureBase()
        
        self._bindCalendarCollectionView()
        self._bindYearMonthText()
        self._bindSelectedDate()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        calendarHeightConstraints.constant = self.calendarCollectionView.contentSize.height
    }
    
    private func _configureBase() {
        self.calendarCollectionView.delegate = self
        CustomCalendarCell.register(to: self.calendarCollectionView)
    }
    
    @IBAction func beforeMonthAction(_ sender: Any) {
        self.viewModel.input.beforeMonth.onNext(())
    }
    
    @IBAction func nextMonthAction(_ sender: Any) {
        self.viewModel.input.nextMonth.onNext(())
    }
    
    private func _bindCalendarCollectionView() {
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<CustomCalendarCellDataSource>(
            configureCell: { dataSource, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CustomCalendarCell.identifier,
                    for: indexPath
                ) as? CustomCalendarCell else { return UICollectionViewCell() }
                
                cell.display(cellModel: item)
                
                return cell
            }
        )
        
        dataSource.animationConfiguration = AnimationConfiguration(
            insertAnimation: .fade,
            reloadAnimation: .fade,
            deleteAnimation: .fade
        )
        
        self.viewModel.output.cellDataSource
            .drive(calendarCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.calendarCollectionView.rx.modelSelected(CustomCalendarCellModel.self)
            .subscribe(onNext: { [weak self] cellModel in
                self?.viewModel.input.selectedItem.onNext(cellModel)
            })
            .disposed(by: disposeBag)
    }
    
    private func _bindYearMonthText() {
        self.viewModel.output.yearMonthText
            .drive(self.yearMonthLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func _bindSelectedDate() {
        self.viewModel.output.selectedDate
            .compactMap { $0 }
            .drive(onNext: { [weak self] date in
                self?.delegate?.didSelectedDate(date: date)
            })
            .disposed(by: disposeBag)
    }
}

extension CustomCalendarView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let minColumnWidth: CGFloat = self.bounds.width / 7
      return CGSize(width: minColumnWidth - 1, height: (minColumnWidth - 1) * (4 / 5) - 2)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
      return 2
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
      return 1
  }
}
