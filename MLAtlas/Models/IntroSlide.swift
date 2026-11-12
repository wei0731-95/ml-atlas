import SwiftUI

/// 首頁「ML 簡介」輪播卡片的資料
struct IntroSlide: Identifiable, Sendable {
    let id: Int
    let title: String
    let subtitle: String
    let text: String
    let symbol: String
    let color: Color

    static let samples: [IntroSlide] = [
        IntroSlide(id: 0, title: "Machine Learning", subtitle: "機器學習是什麼?",
                   text: "不直接寫下規則,而是讓電腦從資料中找出規律,再用來預測或做決策。",
                   symbol: "sparkles", color: Color(red: 0.24, green: 0.14, blue: 0.42)),
        IntroSlide(id: 1, title: "Supervised", subtitle: "監督式學習",
                   text: "資料附有正確答案(標註),模型學習從輸入對應到輸出,例如分類與迴歸。",
                   symbol: "tag.fill", color: MLCategory.supervised.fill),
        IntroSlide(id: 2, title: "Unsupervised", subtitle: "非監督式學習",
                   text: "資料沒有答案,模型自行找出結構,例如分群與降維。",
                   symbol: "circle.hexagongrid.fill", color: MLCategory.unsupervised.fill),
        IntroSlide(id: 3, title: "Deep Learning", subtitle: "深度學習",
                   text: "用多層神經網路自動學習特徵,是影像、語音與語言模型的核心技術。",
                   symbol: "brain.head.profile", color: MLCategory.deepLearning.fill),
        IntroSlide(id: 4, title: "Reinforcement", subtitle: "強化學習",
                   text: "代理人與環境互動,依照獲得的獎勵逐步學會更好的決策策略。",
                   symbol: "gamecontroller.fill", color: MLCategory.reinforcement.fill),
    ]
}
