import ComicInfo
import Foundation
import Testing

@testable import ComicInfoComicVine

struct ComicVineTests {
  private let comicVine = ComicVine(
    apiKey: FixtureURLProtocol.apiKey, userAgent: FixtureURLProtocol.userAgent, session: FixtureURLProtocol.session)
  private let issue = ComicInfo.Issue(number: "1", series: "Futuristic Tales")

  @Test func testItIsCreditedAsComicVine() {
    #expect(comicVine.name == "Comic Vine")
    #expect(comicVine.homeURL.absoluteString == "https://comicvine.gamespot.com/")
  }

  @Test func testItNeedsASeriesAndANumber() {
    #expect(comicVine.missingDetails(for: issue) == nil)
    #expect(comicVine.missingDetails(for: ComicInfo.Issue(number: "1")) != nil)
    #expect(comicVine.missingDetails(for: ComicInfo.Issue(series: "Saga")) != nil)
    #expect(comicVine.missingDetails(for: ComicInfo.Issue(number: " ", series: "Saga")) != nil)
  }

  @Test func testMatchesAreTheNumberedIssueInEveryFoundSeriesOnce() async throws {
    let matches = try await comicVine.matches(for: issue)

    #expect(matches.count == 1)
    let match = try #require(matches.first)
    #expect(match.id == "140529")
    #expect(match.heading == "Cory Doctorow's Futuristic Tales of the Here and Now (2007) #1")
    #expect(match.series == "Cory Doctorow's Futuristic Tales of the Here and Now")
    #expect(match.number == "1")
    #expect(match.title == "Anda's Game")
    #expect(match.coverDate == "2007-10-01")
    #expect(match.details == "IDW Publishing · Cover date 2007-10-01")
    #expect(
      match.siteURL?.absoluteString
        == "https://comicvine.gamespot.com/cory-doctorows-futuristic-tales-of-the-here-and-no/4000-140529/")
  }

  @Test func testTheIssueHasEverythingComicVineKnows() async throws {
    let match = try #require(try await comicVine.matches(for: issue).first)
    let found = try await comicVine.issue(for: match)

    #expect(found.series == "Cory Doctorow's Futuristic Tales of the Here and Now")
    #expect(found.number == "1")
    #expect(found.title == "Anda's Game")
    #expect(found.count == 1)
    #expect(found.year == 2007)
    #expect(found.month == 10)
    #expect(found.day == nil)
    #expect(found.publisher == "IDW Publishing")
    #expect(found.summary?.hasPrefix("For 12-year-old Anda, getting paid real money") == true)
    #expect(found.summary?.contains("<i>") == false)
    #expect(found.webLinks == [match.siteURL!.absoluteString])
  }

  @Test func testCreditsGoToTheirRoles() async throws {
    let match = try #require(try await comicVine.matches(for: issue).first)
    let found = try await comicVine.issue(for: match)

    #expect(found.writer == "Dara Naraghi, Esteve Polls")
    #expect(found.penciller == "Esteve Polls")
    #expect(found.inker == "Esteve Polls")
    #expect(found.colorist == nil)
    #expect(found.letterer == "Neil Uyetake")
    #expect(found.coverArtist == "Sam Kieth")
    #expect(found.editor == "Ted Adams")
  }

  @Test func testCharactersTeamsLocationsAndStoryArcs() async throws {
    let match = try #require(try await comicVine.matches(for: issue).first)
    let found = try await comicVine.issue(for: match)

    #expect(found.characters == ["Anda", "Lucy Kemp"])
    #expect(found.teams == ["The Fahrenheits"])
    #expect(found.locations == ["Coursegold"])
    #expect(found.storyArc == "Futuristic Tales")
  }

  @Test func testAWrongKeyIsComicVinesError() async {
    let wrongKey = ComicVine(
      apiKey: "wrong", userAgent: FixtureURLProtocol.userAgent, session: FixtureURLProtocol.session)
    await #expect(throws: ComicVineError.api("Invalid API Key")) {
      try await wrongKey.matches(for: issue)
    }
  }

  @Test func testAnHTTPErrorIsAnError() async {
    let unnamed = ComicVine(apiKey: FixtureURLProtocol.apiKey, userAgent: "", session: FixtureURLProtocol.session)
    await #expect(throws: ComicVineError.httpStatus(403)) {
      try await unnamed.matches(for: issue)
    }
  }
}
