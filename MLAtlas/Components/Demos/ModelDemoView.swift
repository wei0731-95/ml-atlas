import SwiftUI

// 需求 6:每個模型詳情頁的專屬示意動畫
struct ModelDemoView: View {
    let model: MLModel

    private var tint: Color { model.category.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            demo
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("\(model.name) 示意動畫")

            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var demo: some View {
        let tint = tint
        // 上面會疊白字的動畫改用較深的填色,深色模式下才有足夠對比
        let fill = model.category.fill
        switch model.demo {
        // 互動式動畫(withAnimation / spring)
        case .linearRegression: LinearRegressionDemo(tint: tint)
        case .kMeans: KMeansDemo()
        case .decisionTree: DecisionTreeDemo(tint: fill)
        case .knn: KNNDemo()
        // Canvas + TimelineView 動畫
        case .neuralNetwork:
            canvas { CanvasDemos.network($0, $1, $2, tint, layers: [3, 4, 4, 2], labels: ["Input", "Hidden", "Hidden", "Output"]) }
        case .dqn:
            canvas { CanvasDemos.network($0, $1, $2, tint, layers: [4, 5, 5, 3], labels: ["State", "Hidden", "Hidden", "Q(s, a)"]) }
        case .logisticRegression: canvas { CanvasDemos.logistic($0, $1, $2, tint) }
        case .randomForest: canvas { CanvasDemos.randomForest($0, $1, $2, tint) }
        case .svm: canvas { CanvasDemos.svm($0, $1, $2, tint) }
        case .dbscan: canvas { CanvasDemos.dbscan($0, $1, $2, tint) }
        case .pca: canvas { CanvasDemos.pca($0, $1, $2, tint) }
        case .cnn: canvas { CanvasDemos.cnn($0, $1, $2, tint) }
        case .rnn: canvas { CanvasDemos.rnn($0, $1, $2, fill) }
        case .transformer: canvas { CanvasDemos.transformer($0, $1, $2, fill) }
        case .gan: canvas { CanvasDemos.gan($0, $1, $2, tint) }
        case .qLearning: canvas { CanvasDemos.qLearning($0, $1, $2, tint) }
        }
    }

    private func canvas(_ draw: @escaping (GraphicsContext, CGSize, Double) -> Void) -> some View {
        TimelineCanvas(draw: draw)
            .frame(height: 230)
    }

    private var caption: String {
        switch model.demo {
        case .linearRegression: "梯度下降一步步調整斜率與截距,讓直線與資料點之間的誤差(MSE)越來越小。"
        case .logisticRegression: "S 形的 sigmoid 曲線把輸入轉成 0 到 1 的機率,超過 0.5 就判為正類。"
        case .decisionTree: "節點逐層分裂:每一層問一個問題,把資料分到不同分支,直到葉節點給出答案。"
        case .randomForest: "三棵樹各自走到不同的葉節點並投票,最後以多數決當作森林的預測。"
        case .svm: "分隔線兩側的間隔逐漸放大,直到碰到最近的資料點 —— 也就是支援向量。"
        case .knn: "點一下畫面任意位置放置新資料,最近的 k 個鄰居會被標示出來並投票決定類別。"
        case .kMeans: "重複兩個步驟:把每個點指派給最近的中心,再把中心移到群內的平均位置。"
        case .dbscan: "從密集的點開始,沿著半徑 ε 內的鄰居不斷擴張成群;落單的點被標為雜訊。"
        case .pca: "先找出資料變異最大的方向(PC1),再把所有點投影到這條軸上,完成降維。"
        case .neuralNetwork: "訊號從輸入層出發,沿著連線逐層傳到輸出層(forward pass)。"
        case .cnn: "3×3 的卷積核在輸入影像上滑動,每個位置算出一個值,逐格填滿右邊的特徵圖。"
        case .rnn: "序列一個字一個字讀入,隱藏狀態 h 把先前的資訊傳給下一個時間步。"
        case .transformer: "自注意力:每個字都會參考句子裡的所有字,線條越粗代表注意力權重越高。"
        case .gan: "生成器產生的分布(橘色)逐漸逼近真實資料(紫色),判別器的準確率降到約 50%。"
        case .qLearning: "代理人在格子世界中走向終點;每一回合後,Q 值由終點往回傳遞,顏色越深代表價值越高。"
        case .dqn: "DQN 用神經網路取代 Q 表:輸入狀態,輸出每個動作的 Q 值。"
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            ForEach(MLModel.samples.prefix(3)) { model in
                ModelDemoView(model: model)
            }
        }
        .padding()
    }
}
