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
        let startVerse = BibleDatabase.shared.getVerse(
            bookCode: startVerseId.split(separator: "_")[0].description,
            chapter: Int(startVerseId.split(separator: "_")[1]) ?? 0,
            verse: Int(startVerseId.split(separator: "_")[2]) ?? 0,
            versionCode: versionCode
        )
        
        let endVerse = BibleDatabase.shared.getVerse(
            bookCode: endVerseId.split(separator: "_")[0].description,
            chapter: Int(endVerseId.split(separator: "_")[1]) ?? 0,
            verse: Int(endVerseId.split(separator: "_")[2]) ?? 0,
            versionCode: versionCode
        )
        
        guard let start = startVerse, let end = endVerse else { return nil }
        
        return BibleRange(startVerse: start, endVerse: end, versionCode: versionCode)
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
        let verses = self.verses
        if verses.isEmpty {
            return "암송 구절"
        }
        return verses.map { $0.verseText }.joined(separator: "\n")
    }
    
    var reference: String {
        // 실제 구현에서는 BibleDatabase에서 구절들을 가져와야 함
        let verses = self.verses
        if verses.isEmpty {
            return "성경 구절"
        }
        if verses.count == 1 {
            return verses[0].reference
        }
        return "\(verses[0].reference) - \(verses[verses.count-1].reference)"
    }
    
    var verses: [BibleVerse] {
        // verse_id로 직접 구절을 가져옴
        return verseIds.compactMap { BibleDatabase.shared.getVerseById($0) }
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
    var verseMistakes: [String: [DiffResult]] // verseId별 DiffResult 배열
    
    init(plan: RecitationPlan, testType: TestType, accuracy: Double, totalVerses: Int, correctVerses: Int, incorrectVerses: [BibleVerse], userInput: String, expectedText: String, verseMistakes: [String: [DiffResult]]) {
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
        self.verseMistakes = verseMistakes
    }
    
    var incorrectVerses: [BibleVerse] {
        return incorrectVerseIds.compactMap { BibleDatabase.shared.getVerseById($0) }
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
    
    // 데이터베이스에서 동적으로 가져오므로 static 배열 제거
    static var allBooks: [BibleBook] {
        return BibleDatabase.shared.getAllBooks()
    }
}

// MARK: - 성경 역본 정보
struct BibleVersion: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let code: String
    let language: String
    
    // 데이터베이스에서 동적으로 가져오므로 static 배열 제거
    static var allVersions: [BibleVersion] {
        return BibleDatabase.shared.getAllVersions()
    }
} 

// MARK: - DiffResult 및 Diff 알고리즘

enum DiffType: String, Codable {
    case correct
    case inserted
    case deleted
}

struct DiffResult: Identifiable, Codable {
    let id: UUID
    let word: String
    let index: Int
    let type: DiffType
    init(word: String, index: Int, type: DiffType) {
        self.id = UUID()
        self.word = word
        self.index = index
        self.type = type
    }
}

// MARK: - 텍스트 전처리 함수
func preprocessWords(_ text: String) -> [String] {
    // 구두점 제거, 소문자화, 공백 정리
    let cleaned = text
        .lowercased()
        .replacingOccurrences(of: "[.,!?;:()\\[\\]\"']", with: "", options: .regularExpression)
    return cleaned.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
}

// MARK: - 문자 단위 전처리 함수
func preprocessChars(_ text: String) -> [String] {
    let cleaned = text
        .lowercased()
        .replacingOccurrences(of: "[.,!?;:()\\[\\]\"']", with: "", options: .regularExpression)
    return Array(cleaned).map { String($0) }
}

/// Myers Diff 알고리즘을 사용한 문자 단위 diff
func diffChars(_ original: String, _ input: String) -> [DiffResult] {
    let originalChars = Array(original)
    let inputChars = Array(input)
    
    // Myers Diff 알고리즘 구현
    let n = originalChars.count
    let m = inputChars.count
    
    // 편집 그래프 초기화
    var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
    
    // 첫 번째 행과 열 초기화
    for i in 0...n {
        dp[i][0] = i
    }
    for j in 0...m {
        dp[0][j] = j
    }
    
    // 동적 프로그래밍으로 최소 편집 거리 계산
    for i in 1...n {
        for j in 1...m {
            if originalChars[i-1] == inputChars[j-1] {
                dp[i][j] = dp[i-1][j-1]  // 대각선 이동 (변경 없음)
            } else {
                dp[i][j] = min(dp[i-1][j], dp[i][j-1]) + 1  // 삭제 또는 삽입
            }
        }
    }
    
    // 역추적하여 diff 결과 생성
    var results: [DiffResult] = []
    var i = n, j = m
    var charIndex = 0
    
    while i > 0 || j > 0 {
        if i > 0 && j > 0 && originalChars[i-1] == inputChars[j-1] {
            // 문자가 같음 - 정확함
            results.insert(DiffResult(
                word: String(originalChars[i-1]),
                index: charIndex,
                type: .correct
            ), at: 0)
            i -= 1
            j -= 1
            charIndex += 1
        } else if j > 0 && (i == 0 || dp[i][j-1] <= dp[i-1][j]) {
            // 삽입
            results.insert(DiffResult(
                word: String(inputChars[j-1]),
                index: charIndex,
                type: .inserted
            ), at: 0)
            j -= 1
            charIndex += 1
        } else if i > 0 && (j == 0 || dp[i-1][j] < dp[i][j-1]) {
            // 삭제
            results.insert(DiffResult(
                word: String(originalChars[i-1]),
                index: charIndex,
                type: .deleted
            ), at: 0)
            i -= 1
            charIndex += 1
        }
    }
    
    return results
} 
