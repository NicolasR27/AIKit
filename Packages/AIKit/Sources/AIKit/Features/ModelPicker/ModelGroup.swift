import Foundation

/// Models sharing a `vendor/` prefix. IDs without a slash go in one unnamed group.
struct ModelGroup: Identifiable {
    let vendor: String
    let models: [String]

    var id: String { vendor }

    /// The model ID without its `vendor/` prefix.
    func displayName(for model: String) -> String {
        vendor.isEmpty ? model : String(model.dropFirst(vendor.count + 1))
    }

    static func grouping(_ models: [String]) -> [ModelGroup] {
        Dictionary(grouping: models) { id in
            id.firstIndex(of: "/").map { String(id[..<$0]) } ?? ""
        }
        .map { ModelGroup(vendor: $0.key, models: $0.value) }
        .sorted { $0.vendor < $1.vendor }
    }
}
