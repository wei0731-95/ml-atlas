import SwiftUI

/// 收藏狀態:用 @Observable 管理,並寫入 UserDefaults,重開 App 後仍保留。
@MainActor
@Observable
final class FavoritesStore {
    private static let storageKey = "favoriteModelIDs"
    private(set) var ids: Set<String>

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: Self.storageKey) ?? [])
    }

    func contains(_ model: MLModel) -> Bool {
        ids.contains(model.id)
    }

    func toggle(_ model: MLModel) {
        if ids.contains(model.id) {
            ids.remove(model.id)
        } else {
            ids.insert(model.id)
        }
        UserDefaults.standard.set(ids.sorted(), forKey: Self.storageKey)
    }

    var models: [MLModel] {
        MLModel.samples.filter { ids.contains($0.id) }
    }
}
