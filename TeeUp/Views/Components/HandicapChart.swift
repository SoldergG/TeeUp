import SwiftUI
import Charts

struct HandicapChart: View {
    let records: [HandicapRecord]
    var height: CGFloat = 200

    private var displayRecords: [HandicapRecord] {
        Array(records.sorted { $0.date < $1.date }.suffix(20))
    }

    var body: some View {
        if displayRecords.count >= 2 {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Evolução do Handicap")
                        .font(.headline)
                    Spacer()

                    let trend = HandicapTrend.direction(from: records)
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                        Text(trend.label)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(trend.color)
                }

                Chart(displayRecords, id: \.date) { record in
                    LineMark(
                        x: .value("Data", record.date),
                        y: .value("HCP", record.handicapIndex)
                    )
                    .foregroundStyle(AppTheme.primaryGreen)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Data", record.date),
                        y: .value("HCP", record.handicapIndex)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primaryGreen.opacity(0.3), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Data", record.date),
                        y: .value("HCP", record.handicapIndex)
                    )
                    .foregroundStyle(AppTheme.primaryGreen)
                    .symbolSize(20)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                    }
                }
                .frame(height: height)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
    }
}
