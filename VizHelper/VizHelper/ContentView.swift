import SwiftUI
import Charts


struct ContentView: View {
    @State private var tab: Tab = .metrics
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Mode", selection: $tab) {
                    Text("Metrics").tag(Tab.metrics)
                    Text("ROC & PR").tag(Tab.rocpr)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch tab {
                case .metrics: MetricsView()
                case .rocpr: ROC_PR_View()
                }
            }
            .navigationTitle("Minimal ML Charts")
        }
    }

    enum Tab { case metrics, rocpr }
}


struct MetricsView: View {
    @EnvironmentObject var api: APIClient
    @State private var points: [MetricPoint] = []
    @State private var kind: String = "sine"
    @State private var n: Double = 300
    @State private var noise: Double = 0.05
    @State private var err: String?
    @State private var loading = false

    var body: some View {
        VStack(spacing: 12) {
            // Controls
            HStack(spacing: 12) {
                Picker("Series", selection: $kind) {
                    Text("Sine").tag("sine"); Text("Cosine").tag("cosine")
                    Text("Ramp").tag("ramp"); Text("Random").tag("random")
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("n \(Int(n))").frame(width: 70, alignment: .leading)
                    Slider(value: $n, in: 50...2000, step: 50)
                }
                HStack {
                    Text("noise \(String(format: "%.2f", noise))").frame(width: 130, alignment: .leading)
                    Slider(value: $noise, in: 0...0.5, step: 0.01)
                }

                Button("Load") { Task { await load() } }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            // Chart or state
            if loading {
                ProgressView("Loading…").padding()
            } else if let err {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(err))
                    .padding()
            } else if points.isEmpty {
                ContentUnavailableView("No Data", systemImage: "chart.xyaxis.line", description: Text("Tap Load"))
                    .padding()
            } else {
                Chart(points) { p in
                    LineMark(x: .value("t", p.t),
                             y: .value("y", p.y))
                }
                .frame(minHeight: 320)
                .chartXAxisLabel("t")
                .chartYAxisLabel("y")
                .padding(.horizontal)
            }
            Spacer()
        }
        .task { await load() }
    }

    private func load() async {
        loading = true; err = nil
        defer { loading = false }
        do {
            var resp = try await api.fetchMetrics(kind: kind, n: Int(n), noise: noise)
            // Give stable IDs (optional, nice for Charts)
            resp.points = resp.points.map { MetricPoint(id: UUID(), t: $0.t, y: $0.y) }
            points = resp.points
        } catch {
            err = "Failed to fetch metrics"
            points = []
        }
    }
}

// MARK: - ROC & PR view

struct ROC_PR_View: View {
    @EnvironmentObject var api: APIClient
    @State private var roc: [XYPoint] = []
    @State private var pr:  [XYPoint] = []
    @State private var rocAUC: Double = .nan
    @State private var prAUC:  Double = .nan
    @State private var err: String?
    @State private var loading = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Generate") { Task { await load() } }
                    .buttonStyle(.borderedProminent)
                if !roc.isEmpty { Text(String(format: "ROC AUC: %.3f", rocAUC)) }
                if !pr.isEmpty  { Text(String(format: "PR AUC:  %.3f", prAUC)) }
                Spacer()
            }
            .padding(.horizontal)

            Group {
                Text("ROC Curve")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Chart(roc) { p in
                    LineMark(x: .value("FPR", p.x),
                             y: .value("TPR", p.y))
                }
                .frame(minHeight: 220)
                .chartXScale(domain: 0...1)
                .chartYScale(domain: 0...1)
                .padding(.horizontal)
            }

            Group {
                Text("Precision–Recall Curve")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Chart(pr) { p in
                    LineMark(x: .value("Recall", p.x),
                             y: .value("Precision", p.y))
                }
                .frame(minHeight: 220)
                .chartXScale(domain: 0...1)
                .chartYScale(domain: 0...1)
                .padding(.horizontal)
            }

            if let err {
                ContentUnavailableView("Error",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text(err))
                .padding()
            }
            Spacer()
        }
        .task { await load() }
    }

    private func load() async {
        loading = true; err = nil
        defer { loading = false }
        do {
            var resp = try await api.fetchRocPr()
            resp.roc.points = resp.roc.points.map { XYPoint(id: UUID(), x: $0.x, y: $0.y) }
            resp.pr.points  = resp.pr.points .map { XYPoint(id: UUID(), x: $0.x, y: $0.y) }
            roc = resp.roc.points
            pr  = resp.pr.points
            rocAUC = resp.roc.auc ?? .nan
            prAUC  = resp.pr.auc  ?? .nan
        } catch {
            err = "Failed to fetch ROC/PR"
            roc = []; pr = []
        }
    }
}
