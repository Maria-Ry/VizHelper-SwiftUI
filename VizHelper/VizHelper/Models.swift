import Foundation

// /api/metrics
struct MetricPoint: Identifiable, Codable {
    var id = UUID()
    let t: Double
    let y: Double
}
struct MetricsResponse: Codable {
    let series: String
    var points: [MetricPoint]
}

// /api/metrics/roc_pr
struct XYPoint: Identifiable, Codable {
    var id = UUID()
    let x: Double
    let y: Double
}
struct Curve: Codable {
    var points: [XYPoint]
    let auc: Double?
}
struct RocPrResponse: Codable {
    var roc: Curve
    var pr:  Curve
}
