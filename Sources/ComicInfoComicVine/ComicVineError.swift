//
// ComicVineError.swift
// ComicInfoComicVine
//

import Foundation

/// Why a Comic Vine request failed.
public enum ComicVineError: Error, Equatable, LocalizedError {
  /// Comic Vine answered with an HTTP error status, such as 403 or 503.
  case httpStatus(Int)
  /// Comic Vine answered with an error of its own, such as "Invalid API Key".
  case api(String)

  public var errorDescription: String? {
    switch self {
    case .httpStatus(let status): "Comic Vine answered with HTTP status \(status)."
    case .api(let message): "Comic Vine said: \(message)."
    }
  }
}
