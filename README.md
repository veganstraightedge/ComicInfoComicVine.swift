# ComicInfoComicVine.swift

Looks up comic details in [Comic Vine](https://comicvine.gamespot.com), for [ComicInfo.swift](https://github.com/veganstraightedge/ComicInfo.swift).

`ComicVine` is a `ComicInfo.MetadataSource`: it searches Comic Vine for an issue, and returns what Comic Vine knows about the one picked as a `ComicInfo.Issue`. See [Looking Up Details in Online Databases](https://github.com/veganstraightedge/ComicInfo.swift/blob/main/doc/metadata-sources.md).

## Installation

```swift
dependencies: [
  .package(url: "https://github.com/veganstraightedge/ComicInfoComicVine.swift.git", from: "0.1.0")
]
```

## Usage

```swift
import ComicInfo
import ComicInfoComicVine

let comicVine = ComicVine(apiKey: "your API key", userAgent: "MyApp/1.0")

let issue = ComicInfo.Issue(number: "1", series: "Saga")
let matches = try await comicVine.matches(for: issue)    // best first
let found = try await comicVine.issue(for: matches[0])   // after a person picks one
let updated = issue.fillingBlanks(from: found)
```

- `matches(for:)` needs a Series and a Number; `missingDetails(for:)` says so when either is blank.
- It searches every series whose name matches, so a recent series with a common name isn't missed, and ranks the matches by series name, then cover year.
- `issue(for:)` reads the issue and its series: title, cover year and month, publisher, issue count, summary (as plain text), credits by role, characters, teams, locations, story arcs, and the issue's Comic Vine page as its web link.

## Terms

- An API key comes with a free Comic Vine account: <https://comicvine.gamespot.com/api/>.
- Comic Vine's data is for non-commercial use only, and whatever shows it must credit and link to Comic Vine (`comicVine.name`, `comicVine.homeURL`).
- Comic Vine refuses generic HTTP clients, so `userAgent` must name your app.

## Requirements

- Swift 6.4+
- macOS 27+ or iOS 27+

## Development

```sh
script/test     # swift test
script/lint     # swift format lint --strict
script/format   # swift format --in-place
```

The tests answer every request with a recorded Comic Vine response from `Tests/ComicInfoComicVineTests/Fixtures/`, so they need no key or network.

## License

[MIT](LICENSE.md)
