import Foundation
import Testing
@testable import Atlas

@Suite("Release History Catalog")
struct ReleaseHistoryCatalogTests {
    @Test("Entries track generated releases on top of the reset baseline")
    func entriesCoverReleaseHistory() {
        let entries = ReleaseHistoryCatalog.entries

        #expect(!entries.isEmpty)
        #expect(entries.first?.version == Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        #expect(entries.last?.version == "1.0.0")
        #expect(entries.last?.headline == "重新定位为精简后的新产品起点")
        #expect(Set(entries.map(\.id)).count == entries.count)
        #expect(entries.allSatisfy { entry in
            !entry.headline.isEmpty
                && !entry.changes.isEmpty
                && entry.changes.allSatisfy { !$0.isEmpty }
        })
    }
}
