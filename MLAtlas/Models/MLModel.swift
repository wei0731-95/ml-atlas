import SwiftUI

// 需求 3:資料模型 —— 類別用 enum
enum MLCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case supervised, unsupervised, deepLearning, reinforcement

    var id: String { rawValue }

    var zhName: String {
        switch self {
        case .supervised: "監督式學習"
        case .unsupervised: "非監督式學習"
        case .deepLearning: "深度學習"
        case .reinforcement: "強化學習"
        }
    }

    var enName: String {
        switch self {
        case .supervised: "Supervised"
        case .unsupervised: "Unsupervised"
        case .deepLearning: "Deep Learning"
        case .reinforcement: "Reinforcement"
        }
    }

    var symbol: String {
        switch self {
        case .supervised: "tag.fill"
        case .unsupervised: "circle.hexagongrid.fill"
        case .deepLearning: "brain.head.profile"
        case .reinforcement: "gamecontroller.fill"
        }
    }

    /// 文字與線條用的類別色:Asset Catalog 的 Color Set,Light / Dark 各一組(需求 10)
    var color: Color {
        switch self {
        case .supervised: Color("CatSupervised")
        case .unsupervised: Color("CatUnsupervised")
        case .deepLearning: Color("CatDeep")
        case .reinforcement: Color("CatReinforcement")
        }
    }

    /// 放在白色圖示後面的底色:兩種外觀都用同一個較深的色調,確保對比
    var fill: Color {
        switch self {
        case .supervised: Color(red: 0.33, green: 0.22, blue: 0.56)
        case .unsupervised: Color(red: 0.18, green: 0.46, blue: 0.48)
        case .deepLearning: Color(red: 0.58, green: 0.28, blue: 0.46)
        case .reinforcement: Color(red: 0.66, green: 0.45, blue: 0.22)
        }
    }

    /// 數字標號:01、02…
    var index: String {
        String(format: "%02d", (Self.allCases.firstIndex(of: self) ?? 0) + 1)
    }

    var summary: String {
        switch self {
        case .supervised: "用有標註答案的資料學習輸入到輸出的對應。"
        case .unsupervised: "在沒有標註的資料中找出結構與規律。"
        case .deepLearning: "用多層神經網路自動學習特徵表示。"
        case .reinforcement: "透過與環境互動、依獎勵學習決策策略。"
        }
    }
}

/// 比較表使用的三段等級
enum Level: Int, Sendable {
    case low = 1, medium, high

    var label: String {
        switch self {
        case .low: "低"
        case .medium: "中"
        case .high: "高"
        }
    }
}

/// 是否需要標註資料
enum LabelNeed: Sendable {
    case required, notRequired, reward, depends

    var label: String {
        switch self {
        case .required: "需要"
        case .notRequired: "不需要"
        case .reward: "用獎勵訊號"
        case .depends: "視任務而定"
        }
    }

    var symbol: String {
        switch self {
        case .required: "checkmark.circle.fill"
        case .notRequired: "xmark.circle"
        case .reward: "star.circle.fill"
        case .depends: "questionmark.circle"
        }
    }
}

/// 詳情頁專屬示意動畫的種類(需求 6)
enum DemoKind: Sendable {
    case linearRegression, logisticRegression, decisionTree, randomForest, svm, knn
    case kMeans, dbscan, pca
    case neuralNetwork, cnn, rnn, transformer, gan
    case qLearning, dqn
}

// 需求 3:自訂型別遵從 Identifiable
struct MLModel: Identifiable, Hashable, Sendable {
    let id: String              // 固定的代號,用來儲存收藏
    let name: String            // 英文名
    let zhName: String          // 中文名
    let category: MLCategory
    let symbol: String          // SF Symbol 名稱
    let tagline: String         // 一句話簡介
    let concept: String         // 概念
    let mechanism: String       // 原理
    let applications: [String]  // 適用場景
    let pros: [String]
    let cons: [String]
    let algorithms: [String]    // 代表演算法 / 變體
    let difficulty: Int         // 難度 1...5
    let wikiURL: URL
    let docURL: URL?            // scikit-learn 文件(若有)
    let demo: DemoKind
    // 比較表欄位(需求 12)
    let labelNeed: LabelNeed
    let interpretability: Level
    let trainingCost: Level
    let typicalUse: String

    static func == (lhs: MLModel, rhs: MLModel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension MLModel {
    static func models(in category: MLCategory) -> [MLModel] {
        samples.filter { $0.category == category }
    }
}
