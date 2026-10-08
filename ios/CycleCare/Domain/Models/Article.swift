import Foundation

struct Article: Codable, Identifiable {
    let id: String
    var title: String
    var body: String
    var category: String
    var locale: String
    var isPremium: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        category: String,
        locale: String = "vi",
        isPremium: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category
        self.locale = locale
        self.isPremium = isPremium
    }
}
