import Foundation

enum AppLink: String {
    case privacyPolicy = "https://clarivault267shelvora.site/privacy/353"
    case termsOfUse = "https://clarivault267shelvora.site/terms/353"

    var url: URL? {
        URL(string: rawValue)
    }
}
