//
// IssueMapping.swift
// ComicInfoComicVine
//

import ComicInfo
import Foundation
import SwiftSoup

/// A Comic Vine issue and its volume, as a `ComicInfo.Issue`.
struct IssueMapping {
  let issue: ComicInfo.Issue

  init(issue found: Responses.Issue, volume: Responses.Volume) {
    let credits = Credits(found.personCredits ?? [])
    let coverDate = CoverDate(found.coverDate)
    let count = volume.countOfIssues.flatMap { $0 > 0 ? $0 : nil }

    issue = ComicInfo.Issue(
      colorist: credits.names("colorist", "colourist"),
      count: count,
      coverArtist: credits.names("cover"),
      editor: credits.names("editor"),
      inker: credits.names("inker", "artist"),
      letterer: credits.names("letterer"),
      month: coverDate.month,
      number: ComicVine.nonBlank(found.issueNumber),
      penciller: credits.names("penciler", "penciller", "artist"),
      publisher: ComicVine.nonBlank(volume.publisher?.name),
      series: ComicVine.nonBlank(volume.name ?? found.volume.name),
      storyArc: Self.joined(found.storyArcCredits),
      summary: Self.plainText(found.description) ?? Self.plainText(found.deck),
      title: ComicVine.nonBlank(found.name),
      writer: credits.names("writer"),
      year: coverDate.year
    )
    .settingCharacters(Self.names(found.characterCredits))
    .settingTeams(Self.names(found.teamCredits))
    .settingLocations(Self.names(found.locationCredits))
    .settingWebLinks([found.siteDetailUrl].compactMap(\.self))
  }

  private static func names(_ references: [Responses.Reference]?) -> [String] {
    (references ?? []).compactMap(\.name)
  }

  private static func joined(_ references: [Responses.Reference]?) -> String? {
    ComicVine.nonBlank(names(references).joined(separator: ", "))
  }

  /// An HTML fragment's text, whitespace collapsed.
  private static func plainText(_ html: String?) -> String? {
    guard let html, let text = try? SwiftSoup.parseBodyFragment(html).text() else { return nil }
    return ComicVine.nonBlank(text)
  }
}

/// A cover date such as "2007-10-01", as a year and month.
///
/// The day is left out: Comic Vine writes the 1st when it only knows the month.
private struct CoverDate {
  let year: Int?
  let month: Int?

  init(_ text: String?) {
    let parts = (text ?? "").split(separator: "-")
    year = parts.count >= 2 ? Int(parts[0]) : nil
    month = parts.count >= 2 ? Int(parts[1]) : nil
  }
}

/// The people credited on an issue, by lowercase role.
private struct Credits {
  private let namesByRole: [String: [String]]

  init(_ people: [Responses.Credit]) {
    var namesByRole: [String: [String]] = [:]
    for person in people {
      for role in (person.role ?? "").split(separator: ",") {
        let role = role.trimmingCharacters(in: .whitespaces).lowercased()
        namesByRole[role, default: []].append(person.name)
      }
    }
    self.namesByRole = namesByRole
  }

  /// Everyone credited with any of `roles`, each once, in order, or `nil` when no one is.
  func names(_ roles: String...) -> String? {
    var people: [String] = []
    for role in roles {
      for person in namesByRole[role, default: []] where !people.contains(person) {
        people.append(person)
      }
    }
    return people.isEmpty ? nil : people.joined(separator: ", ")
  }
}
