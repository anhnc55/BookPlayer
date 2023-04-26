//
//  SimpleBookmark.swift
//  BookPlayer
//
//  Created by gianni.carlo on 23/4/23.
//  Copyright © 2023 Tortuga Power. All rights reserved.
//

import Foundation

public struct SimpleBookmark: Decodable {
  public let time: Double
  public let note: String?
  let type: BookmarkType
  public let relativePath: String

  static var fetchRequestProperties = [
    "time",
    "note",
    "type",
    "item.relativePath",
  ]

  public func getImageNameForType() -> String? {
    switch type {
    case .play:
      return "play"
    case .skip:
      return "clock.arrow.2.circlepath"
    case .user:
      return nil
    }
  }
}
