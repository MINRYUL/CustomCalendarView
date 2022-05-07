//
//  CustomCalendarViewModel.swift
//  CustomCalendarView
//
//  Created by 김민창 on 2022/05/03.
//

import Foundation

import RxSwift
import RxCocoa

struct CustomCalendarViewModelInput {
    let selectedItem: BehaviorSubject<CustomCalendarCellModel?>
    let beforeMonth: BehaviorSubject<Void?>
    let nextMonth: BehaviorSubject<Void?>
}

struct CustomCalendarViewModelOutput {
    let yearMonthText: Driver<String>
    let currentMonth: Driver<String>
    let selectedDate: Driver<Date?>
    let cellDataSource: Driver<[CustomCalendarCellDataSource]>
}

final class CustomCalendarViewModel {
    
    var disposeBag: DisposeBag = DisposeBag()
    
    let input: CustomCalendarViewModelInput
    let output: CustomCalendarViewModelOutput
    
    private let _selectedItem = BehaviorSubject<CustomCalendarCellModel?>(value: nil)
    private let _beforeMonth = BehaviorSubject<Void?>(value: nil)
    private let _nextMonth = BehaviorSubject<Void?>(value: nil)
    
    private let _yearMonthText = BehaviorSubject<String>(value: "")
    private let _currentMonth = BehaviorSubject<String>(value: "")
    private let _selectedDate = BehaviorSubject<Date?>(value: nil)
    private let _cellDataSource = BehaviorSubject<[CustomCalendarCellDataSource]>(value: [])
    
    private let _dateFormatter = DateFormatter()
    private let _dayFormatter = DateFormatter()
    
    private let _currentDate = Date()
    private var _calendar = Calendar.init(identifier: .gregorian)
    private var _components = DateComponents()
    private var _beforeComponents = DateComponents()
    
    init() {
        self.input = CustomCalendarViewModelInput(
            selectedItem: _selectedItem.asObserver(),
            beforeMonth: _beforeMonth.asObserver(),
            nextMonth: _nextMonth.asObserver()
        )
        self.output = CustomCalendarViewModelOutput(
            yearMonthText: _yearMonthText.asDriver(onErrorJustReturn: ""),
            currentMonth: _currentMonth.asDriver(onErrorJustReturn: ""),
            selectedDate: _selectedDate.asDriver(onErrorJustReturn: nil),
            cellDataSource: _cellDataSource.asDriver(onErrorJustReturn: [])
        )
        
        self._configure()
        
        self._bindSelectedItem()
        self._bindBeforeMonth()
        self._bindNextMonth()
    }
    
    private func _configure() {
        self._dateFormatter.dateFormat = "yyyy.MM"
        self._dayFormatter.dateFormat = "yyyyMMdd"
        
        self._configureCalendar(self._currentDate)
    }
    
    private func _configureCalendar(_ date: Date) {
        let currentYear = _calendar.component(.year, from: date)
        let currentMonth = _calendar.component(.month, from: date)
        
        self._components.year = currentYear
        self._components.month = currentMonth
        self._components.day = 1
        
        self._beforeComponents.year = currentYear
        self._beforeComponents.month = currentMonth - 1
        self._beforeComponents.day = 1
        
        self._configureCalendar()
    }
    
    private func _configureCalendar() {
        guard let firstDayOfMonth = _calendar.date(from: _components),
              let beforeDayOfMonth = _calendar.date(from: _beforeComponents),
              let daysCountInMonth = _calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count,
              let daysCountBeforeMonth = _calendar.range(of: .day, in: .month, for: beforeDayOfMonth)?.count
        else { return }
        
        let firstWeekday = 2 - _calendar.component(.weekday, from: firstDayOfMonth)
        
        let currentMonth = self._components.month ?? 12
        let yearMonth = _dateFormatter.string(from: firstDayOfMonth)
        self._yearMonthText.onNext(yearMonth)
        
        var cellModels = [CustomCalendarCellModel]()
        
        for day in firstWeekday...daysCountInMonth {
            var tempComponents = _components
            tempComponents.day = day
            if day < 1 {
                cellModels.append(CustomCalendarCellModel(
                    identity: UUID().uuidString,
                    isCurrentMonth: false,
                    isSelected: isSelectedDate(_calendar.date(from: tempComponents)),
                    isCurrentDay: false,
                    day: daysCountBeforeMonth + day,
                    date: _calendar.date(from: tempComponents))
                )
            } else {
                cellModels.append(CustomCalendarCellModel(
                    identity: UUID().uuidString,
                    isCurrentMonth: true,
                    isSelected: isSelectedDate(_calendar.date(from: tempComponents)),
                    isCurrentDay: isSameDate(_calendar.date(from: tempComponents)),
                    day: day,
                    date: _calendar.date(from: tempComponents))
                )
            }
        }
        
        var nextDay = 1
        
        while cellModels.count % 7 != 0 {
            var tempComponents = _components
            tempComponents.month = currentMonth + 1
            tempComponents.day = nextDay
            
            cellModels.append(CustomCalendarCellModel(
                identity: UUID().uuidString,
                isCurrentMonth: false,
                isSelected: isSelectedDate(_calendar.date(from: tempComponents)),
                isCurrentDay: false,
                day: nextDay,
                date: _calendar.date(from: tempComponents))
            )
            nextDay += 1
        }
        
        self._cellDataSource.onNext([
            CustomCalendarCellDataSource(items: cellModels, identity: UUID().uuidString)
        ])
    }
    
    private func isSelectedDate(_ date: Date?) -> Bool {
        guard let compareDate = try? self._selectedDate.value(),
              let date = date else { return false }
        
        let firstDate = _dayFormatter.string(from: compareDate)
        let secondDate = _dayFormatter.string(from: date)
        
        return firstDate == secondDate
    }
    
    private func isSameDate(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        
        let firstDate = _dayFormatter.string(from: self._currentDate)
        let secondDate = _dayFormatter.string(from: date)
        
        return firstDate == secondDate
    }
}

//MARK: - Binding
extension CustomCalendarViewModel {
    private func _bindSelectedItem() {
        self._selectedItem
            .compactMap { $0 }
            .subscribe(onNext : { [weak self] model in
                guard let self = self,
                      let cellDataSource = try? self._cellDataSource.value(),
                      let cellModels = cellDataSource.first else { return }
                
                let dataSource = cellModels.items.map { cell -> CustomCalendarCellModel in
                    if model.identity == cell.identity {
                        self._selectedDate.onNext(model.date ?? Date())
                        return CustomCalendarCellModel(
                            identity: cell.identity,
                            isCurrentMonth: cell.isCurrentMonth,
                            isSelected: true,
                            isCurrentDay: cell.isCurrentDay,
                            day: cell.day,
                            date: cell.date
                        )
                    }
                    return CustomCalendarCellModel(
                        identity: cell.identity,
                        isCurrentMonth: cell.isCurrentMonth,
                        isSelected: false,
                        isCurrentDay: cell.isCurrentDay,
                        day: cell.day,
                        date: cell.date
                    )
                }
                
                self._cellDataSource.onNext([
                    CustomCalendarCellDataSource(items: dataSource, identity: cellModels.identity)
                ])
            })
            .disposed(by: disposeBag)
    }
  
    private func _bindBeforeMonth() {
        self._beforeMonth
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self,
                      let month = self._components.month else { return }
                
                self._beforeComponents.month = month - 2
                self._components.month = month - 1
                self._configureCalendar()
            })
            .disposed(by: disposeBag)
  }
  
    private func _bindNextMonth() {
        self._nextMonth
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self,
                      let month = self._components.month else { return }
                
                self._beforeComponents.month = month
                self._components.month = month + 1
                self._configureCalendar()
                
            })
            .disposed(by: disposeBag)
  }
}
