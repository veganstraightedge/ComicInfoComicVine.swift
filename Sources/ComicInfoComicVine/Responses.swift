//
// Responses.swift
// ComicInfoComicVine
//

import Foundation

/// Comic Vine's API responses, as far as they are read.
/// See https://comicvine.gamespot.com/api/documentation
enum Responses {
  /// Every response's status. `statusCode` 1 is success; anything else comes with an `error`.
  struct Status: Decodable {
    let error: String
    let statusCode: Int
  }

  /// A successful response's wrapper.
  struct Envelope<Results: Decodable>: Decodable {
    let results: Results
  }

  /// A related resource as Comic Vine embeds it in another.
  struct Reference: Decodable {
    let id: Int
    let name: String?
    let siteDetailUrl: String?
  }

  /// A series ("volume" in Comic Vine's words).
  struct Volume: Decodable {
    let countOfIssues: Int?
    let id: Int
    let name: String?
    let publisher: Reference?
    let siteDetailUrl: String?
    let startYear: String?
  }

  /// An issue as the issues list returns it.
  struct IssueSummary: Decodable {
    let coverDate: String?
    let id: Int
    let issueNumber: String?
    let name: String?
    let siteDetailUrl: String?
    let volume: Reference
  }

  /// A person who worked on an issue. `role` is a comma-separated list, such as "artist, writer".
  struct Credit: Decodable {
    let id: Int
    let name: String
    let role: String?
  }

  /// One issue's full detail.
  struct Issue: Decodable {
    let characterCredits: [Reference]?
    let coverDate: String?
    let deck: String?
    let description: String?
    let id: Int
    let issueNumber: String?
    let locationCredits: [Reference]?
    let name: String?
    let personCredits: [Credit]?
    let siteDetailUrl: String?
    let storyArcCredits: [Reference]?
    let teamCredits: [Reference]?
    let volume: Reference
  }
}
