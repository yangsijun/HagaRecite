import Foundation
import SwiftData

// MARK: - 성경 구절 모델
struct BibleVerse: Identifiable, Codable {
    let id: String
    let bookCode: String
    let bookName: String
    let bookOrder: Int
    let chapter: Int
    let verse: Int
    let verseText: String
    let versionCode: String
    
    var reference: String {
        "\(bookName) \(chapter):\(verse)"
    }
    
    var fullReference: String {
        "\(bookName) \(chapter):\(verse) (\(versionCode))"
    }
}

// MARK: - 성경 범위 모델
struct BibleRange: Codable {
    let startVerse: BibleVerse
    let endVerse: BibleVerse
    let versionCode: String
    
    var totalVerses: Int {
        // 간단한 계산 (실제로는 더 복잡한 로직 필요)
        if startVerse.bookCode == endVerse.bookCode && startVerse.chapter == endVerse.chapter {
            return endVerse.verse - startVerse.verse + 1
        }
        return 0 // 임시값
    }
    
    var displayName: String {
        if startVerse.bookCode == endVerse.bookCode {
            if startVerse.chapter == endVerse.chapter {
                return "\(startVerse.bookName) \(startVerse.chapter):\(startVerse.verse)-\(endVerse.verse)"
            } else {
                return "\(startVerse.bookName) \(startVerse.chapter):\(startVerse.verse)-\(endVerse.chapter):\(endVerse.verse)"
            }
        }
        return "\(startVerse.reference) - \(endVerse.reference)"
    }
}

// MARK: - 암송 계획 모델
@Model
class RecitationPlan {
    var id: UUID
    var title: String
    var startVerseId: String
    var endVerseId: String
    var versionCode: String
    var startDate: Date
    var targetDate: Date
    var isCompleted: Bool
    var createdAt: Date
    var dailyVerses: [DailyVerse]
    
    init(title: String, startVerse: BibleVerse, endVerse: BibleVerse, startDate: Date, targetDate: Date) {
        self.id = UUID()
        self.title = title
        self.startVerseId = startVerse.id
        self.endVerseId = endVerse.id
        self.versionCode = startVerse.versionCode
        self.startDate = startDate
        self.targetDate = targetDate
        self.isCompleted = false
        self.createdAt = Date()
        self.dailyVerses = []
    }
    
    var progress: Double {
        let completedDays = dailyVerses.filter { $0.isCompleted }.count
        let totalDays = dailyVerses.count
        return totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0.0
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.day], from: today, to: targetDate)
        return max(0, components.day ?? 0)
    }
    
    var bibleRange: BibleRange? {
        // 실제 구현에서는 BibleDatabase에서 구절을 가져와야 함
        // 여기서는 임시로 nil을 반환
        return nil
    }
}

// MARK: - 일일 암송 구절 모델
@Model
class DailyVerse {
    var id: UUID
    var date: Date
    var verseIds: [String]
    var isCompleted: Bool
    var completedAt: Date?
    var plan: RecitationPlan?
    
    init(date: Date, verses: [BibleVerse], plan: RecitationPlan) {
        self.id = UUID()
        self.date = date
        self.verseIds = verses.map { $0.id }
        self.isCompleted = false
        self.plan = plan
    }
    
    var displayText: String {
        // 실제 구현에서는 BibleDatabase에서 구절들을 가져와야 함
        return "암송 구절"
    }
    
    var reference: String {
        // 실제 구현에서는 BibleDatabase에서 구절들을 가져와야 함
        return "성경 구절"
    }
    
    var verses: [BibleVerse] {
        // 실제 구현에서는 BibleDatabase에서 구절들을 가져와야 함
        return []
    }
}

// MARK: - 테스트 결과 모델
@Model
class TestResult {
    var id: UUID
    var plan: RecitationPlan
    var testDate: Date
    var testType: TestType
    var accuracy: Double
    var totalVerses: Int
    var correctVerses: Int
    var incorrectVerseIds: [String]
    var userInput: String
    var expectedText: String
    
    init(plan: RecitationPlan, testType: TestType, accuracy: Double, totalVerses: Int, correctVerses: Int, incorrectVerses: [BibleVerse], userInput: String, expectedText: String) {
        self.id = UUID()
        self.plan = plan
        self.testDate = Date()
        self.testType = testType
        self.accuracy = accuracy
        self.totalVerses = totalVerses
        self.correctVerses = correctVerses
        self.incorrectVerseIds = incorrectVerses.map { $0.id }
        self.userInput = userInput
        self.expectedText = expectedText
    }
    
    var incorrectVerses: [BibleVerse] {
        // 실제 구현에서는 BibleDatabase에서 구절들을 가져와야 함
        return []
    }
}

// MARK: - 테스트 타입
enum TestType: String, CaseIterable, Codable {
    case daily = "daily"
    case cumulative = "cumulative"
    
    var displayName: String {
        switch self {
        case .daily:
            return "오늘 분량"
        case .cumulative:
            return "누적 테스트"
        }
    }
}

// MARK: - 성경 책 정보
struct BibleBook: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let code: String
    let order: Int
    let chapters: Int
    
    static let allBooks: [BibleBook] = [
        BibleBook(id: "gen", name: "창세기", code: "GEN", order: 1, chapters: 50),
        BibleBook(id: "exo", name: "출애굽기", code: "EXO", order: 2, chapters: 40),
        BibleBook(id: "lev", name: "레위기", code: "LEV", order: 3, chapters: 27),
        BibleBook(id: "num", name: "민수기", code: "NUM", order: 4, chapters: 36),
        BibleBook(id: "deu", name: "신명기", code: "DEU", order: 5, chapters: 34),
        BibleBook(id: "jos", name: "여호수아", code: "JOS", order: 6, chapters: 24),
        BibleBook(id: "jud", name: "사사기", code: "JUD", order: 7, chapters: 21),
        BibleBook(id: "rut", name: "룻기", code: "RUT", order: 8, chapters: 4),
        BibleBook(id: "1sa", name: "사무엘상", code: "1SA", order: 9, chapters: 31),
        BibleBook(id: "2sa", name: "사무엘하", code: "2SA", order: 10, chapters: 24),
        BibleBook(id: "1ki", name: "열왕기상", code: "1KI", order: 11, chapters: 22),
        BibleBook(id: "2ki", name: "열왕기하", code: "2KI", order: 12, chapters: 25),
        BibleBook(id: "1ch", name: "역대상", code: "1CH", order: 13, chapters: 29),
        BibleBook(id: "2ch", name: "역대하", code: "2CH", order: 14, chapters: 36),
        BibleBook(id: "ezr", name: "에스라", code: "EZR", order: 15, chapters: 10),
        BibleBook(id: "neh", name: "느헤미야", code: "NEH", order: 16, chapters: 13),
        BibleBook(id: "est", name: "에스더", code: "EST", order: 17, chapters: 10),
        BibleBook(id: "job", name: "욥기", code: "JOB", order: 18, chapters: 42),
        BibleBook(id: "psa", name: "시편", code: "PSA", order: 19, chapters: 150),
        BibleBook(id: "pro", name: "잠언", code: "PRO", order: 20, chapters: 31),
        BibleBook(id: "ecc", name: "전도서", code: "ECC", order: 21, chapters: 12),
        BibleBook(id: "sng", name: "아가", code: "SNG", order: 22, chapters: 8),
        BibleBook(id: "isa", name: "이사야", code: "ISA", order: 23, chapters: 66),
        BibleBook(id: "jer", name: "예레미야", code: "JER", order: 24, chapters: 52),
        BibleBook(id: "lam", name: "예레미야애가", code: "LAM", order: 25, chapters: 5),
        BibleBook(id: "eze", name: "에스겔", code: "EZE", order: 26, chapters: 48),
        BibleBook(id: "dan", name: "다니엘", code: "DAN", order: 27, chapters: 12),
        BibleBook(id: "hos", name: "호세아", code: "HOS", order: 28, chapters: 14),
        BibleBook(id: "jol", name: "요엘", code: "JOL", order: 29, chapters: 3),
        BibleBook(id: "amo", name: "아모스", code: "AMO", order: 30, chapters: 9),
        BibleBook(id: "oba", name: "오바댜", code: "OBA", order: 31, chapters: 1),
        BibleBook(id: "jon", name: "요나", code: "JON", order: 32, chapters: 4),
        BibleBook(id: "mic", name: "미가", code: "MIC", order: 33, chapters: 7),
        BibleBook(id: "nah", name: "나훔", code: "NAH", order: 34, chapters: 3),
        BibleBook(id: "hab", name: "하박국", code: "HAB", order: 35, chapters: 3),
        BibleBook(id: "zep", name: "스바냐", code: "ZEP", order: 36, chapters: 3),
        BibleBook(id: "hag", name: "학개", code: "HAG", order: 37, chapters: 2),
        BibleBook(id: "zec", name: "스가랴", code: "ZEC", order: 38, chapters: 14),
        BibleBook(id: "mal", name: "말라기", code: "MAL", order: 39, chapters: 4),
        BibleBook(id: "mat", name: "마태복음", code: "MAT", order: 40, chapters: 28),
        BibleBook(id: "mrk", name: "마가복음", code: "MRK", order: 41, chapters: 16),
        BibleBook(id: "luk", name: "누가복음", code: "LUK", order: 42, chapters: 24),
        BibleBook(id: "jhn", name: "요한복음", code: "JHN", order: 43, chapters: 21),
        BibleBook(id: "act", name: "사도행전", code: "ACT", order: 44, chapters: 28),
        BibleBook(id: "rom", name: "로마서", code: "ROM", order: 45, chapters: 16),
        BibleBook(id: "1co", name: "고린도전서", code: "1CO", order: 46, chapters: 16),
        BibleBook(id: "2co", name: "고린도후서", code: "2CO", order: 47, chapters: 13),
        BibleBook(id: "gal", name: "갈라디아서", code: "GAL", order: 48, chapters: 6),
        BibleBook(id: "eph", name: "에베소서", code: "EPH", order: 49, chapters: 6),
        BibleBook(id: "php", name: "빌립보서", code: "PHP", order: 50, chapters: 4),
        BibleBook(id: "col", name: "골로새서", code: "COL", order: 51, chapters: 4),
        BibleBook(id: "1th", name: "데살로니가전서", code: "1TH", order: 52, chapters: 5),
        BibleBook(id: "2th", name: "데살로니가후서", code: "2TH", order: 53, chapters: 3),
        BibleBook(id: "1ti", name: "디모데전서", code: "1TI", order: 54, chapters: 6),
        BibleBook(id: "2ti", name: "디모데후서", code: "2TI", order: 55, chapters: 4),
        BibleBook(id: "tit", name: "디도서", code: "TIT", order: 56, chapters: 3),
        BibleBook(id: "phm", name: "빌레몬서", code: "PHM", order: 57, chapters: 1),
        BibleBook(id: "heb", name: "히브리서", code: "HEB", order: 58, chapters: 13),
        BibleBook(id: "jas", name: "야고보서", code: "JAS", order: 59, chapters: 5),
        BibleBook(id: "1pe", name: "베드로전서", code: "1PE", order: 60, chapters: 5),
        BibleBook(id: "2pe", name: "베드로후서", code: "2PE", order: 61, chapters: 3),
        BibleBook(id: "1jn", name: "요한일서", code: "1JN", order: 62, chapters: 5),
        BibleBook(id: "2jn", name: "요한이서", code: "2JN", order: 63, chapters: 1),
        BibleBook(id: "3jn", name: "요한삼서", code: "3JN", order: 64, chapters: 1),
        BibleBook(id: "jud", name: "유다서", code: "JUD", order: 65, chapters: 1),
        BibleBook(id: "rev", name: "요한계시록", code: "REV", order: 66, chapters: 22)
    ]
}

// MARK: - 성경 역본 정보
struct BibleVersion: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let code: String
    let language: String
    
    static let allVersions: [BibleVersion] = [
        BibleVersion(id: "krv", name: "개역개정", code: "KRV", language: "ko"),
        BibleVersion(id: "niv", name: "NIV", code: "NIV", language: "en"),
        BibleVersion(id: "kjv", name: "KJV", code: "KJV", language: "en")
    ]
} 
