import Foundation

/// Export round data to CSV or JSON for sharing/backup
enum ExportManager {
    // MARK: - CSV Export
    static func roundsToCSV(_ rounds: [Round]) -> String {
        var csv = "Data,Campo,Score,Par,Diferencial,Putts,Fairways,GIR,Notas\n"

        for round in rounds {
            let date = round.date.shortDate
            let course = round.courseName.replacingOccurrences(of: ",", with: ";")
            let score = round.totalScore
            let par = round.holeScores.reduce(0) { $0 + $1.par }
            let diff = String(format: "%.1f", round.differential)
            let putts = round.totalPutts
            let fairways = round.fairwayPercentage
            let gir = round.girPercentage
            let notes = (round.notes ?? "").replacingOccurrences(of: ",", with: ";")

            csv += "\(date),\(course),\(score),\(par),\(diff),\(putts),\(fairways),\(gir),\(notes)\n"
        }

        return csv
    }

    // MARK: - JSON Export
    static func roundsToJSON(_ rounds: [Round]) -> Data? {
        let exportData = rounds.map { round -> [String: Any] in
            [
                "date": round.date.iso8601,
                "course": round.courseName,
                "totalScore": round.totalScore,
                "differential": round.differential,
                "totalPutts": round.totalPutts,
                "isCompleted": round.isCompleted,
                "holes": round.holeScores.map { hole -> [String: Any] in
                    [
                        "number": hole.holeNumber,
                        "par": hole.par,
                        "score": hole.grossScore,
                        "putts": hole.putts,
                        "fairwayHit": hole.fairwayHit
                    ]
                }
            ]
        }

        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }

    // MARK: - Save to temp file
    static func saveCSVToTemp(_ csv: String, filename: String = "teeup_rounds") -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func saveJSONToTemp(_ data: Data, filename: String = "teeup_rounds") -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename).json")
        try? data.write(to: url)
        return url
    }
}
