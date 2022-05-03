//
//  CustomCalendarModel.swift
//  CustomCalendarView
//
//  Created by 김민창 on 2022/05/03.
//

import Foundation

import RxDataSources

struct CustomCalendarCellDataSource {
  var items: [CustomCalendarCellModel]
  var identity: String
}

struct CustomCalendarCellModel: IdentifiableType, Equatable {
  typealias Identity = String
  
  var identity: Identity
  
  let isCurrentMonth: Bool
  let isSelected: Bool
  let isCurrentDay: Bool
  let day: Int
  let date: Date?
}

extension CustomCalendarCellDataSource: AnimatableSectionModelType {
  init(original: CustomCalendarCellDataSource, items: [CustomCalendarCellModel]) {
    self = original
    self.items = items
  }
}
