# Papago Swift
Papago for Swift is a wrapper for the Papago Text Translation Service API.

With this library, you can translate text from one language to another in a convenient and efficient manner.

## Features
- Supports multiple source and target languages.
- Option to specify whether to use honorifics in the translation.

## Requirements
- Naver Client Key
- Naver Client Secret

## Installation
Papago Swift is available through [Swift Package Manager](https://swift.org/package-manager/). To install it, simply add the following line to your `Package.swift` file's dependencies:

```swift
.package(url: "https://github.com/pepebecker/papago-swift", from: "0.1.0")
```
Also add the following `product` your your target's dependencies:

```swift
.product(name: "Papago", package: "papago-swift"),
```
And then run swift package update to fetch the dependencies.

You can also add Papago Swift to your Xcode project by going to File > Swift Packages > Add Package Dependency... and entering the repository URL.

## Usage
To use the library, you first need to create an instance of the Papago class with your Naver API key:
```swift
let papago = Papago(config: Papago.Config(clientId: "your_client_id", clientSecret: "your_client_secret"))
```

Then, you can translate text using the translate method:
```swift
papago.translate(text: "Hello world!", source: .en, target: .ko) { result in
  switch result {
  case .success(let translation):
    print(translation)
  case .failure(let error):
    print(error)
  }
}
```

## License
Papago Swift is released under the ISC license. [See LICENSE](LICENSE) for details.

## Contributing

If you **have a question**, **found a bug** or want to **propose a feature**, have a look at [the issues page](https://github.com/pepebecker/papago-swift/issues).
