import Foundation
import SwiftData

@MainActor
class TestManager: ObservableObject {
    @Published var currentTest: TestSession?
    @Published var testResults: [TestResult] = []
    
    private let bibleDatabase = BibleDatabase.shared
    
    init() {
        loadTestResults()
    }
    
    // MARK: - 테스트 세션 관리
    
    func startTest(plan: RecitationPlan, testType: TestType) -> TestSession {
        let verses = getVersesForTest(plan: plan, testType: testType)
        let session = TestSession(plan: plan, testType: testType, verses: verses)
        currentTest = session
        return session
    }
    
    func endTest() {
        currentTest = nil
    }
    
    private func getVersesForTest(plan: RecitationPlan, testType: TestType) -> [BibleVerse] {
        switch testType {
        case .daily:
            return getTodayVerses(plan: plan)
        case .cumulative:
            return getCumulativeVerses(plan: plan)
        }
    }
    
    private func getTodayVerses(plan: RecitationPlan) -> [BibleVerse] {
        let today = Date()
        guard let todayVerse = plan.dailyVerses.first(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: today) 
        }) else {
            return []
        }
        return todayVerse.verses
    }
    
    private func getCumulativeVerses(plan: RecitationPlan) -> [BibleVerse] {
        let today = Date()
        var allVerses: [BibleVerse] = []
        
        for dailyVerse in plan.dailyVerses {
            if dailyVerse.date <= today {
                allVerses.append(contentsOf: dailyVerse.verses)
            }
        }
        
        return allVerses
    }
    
    // MARK: - 테스트 결과 처리
    
    func submitTestResult(userInput: String, expectedText: String, verses: [BibleVerse]) -> TestResult {
        let accuracy = calculateAccuracy(userInput: userInput, expectedText: expectedText)
        let (correctVerses, incorrectVerses) = analyzeVerses(userInput: userInput, expectedText: expectedText, verses: verses)
        
        guard let currentTest = currentTest else {
            fatalError("현재 테스트 세션이 없습니다.")
        }
        
        let result = TestResult(
            plan: currentTest.plan,
            testType: currentTest.testType,
            accuracy: accuracy,
            totalVerses: verses.count,
            correctVerses: correctVerses.count,
            incorrectVerses: incorrectVerses,
            userInput: userInput,
            expectedText: expectedText
        )
        
        testResults.append(result)
        saveTestResults()
        
        return result
    }
    
    private func calculateAccuracy(userInput: String, expectedText: String) -> Double {
        let userWords = userInput.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let expectedWords = expectedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        guard !expectedWords.isEmpty else { return 0.0 }
        
        let correctWords = userWords.enumerated().filter { index, word in
            index < expectedWords.count && word == expectedWords[index]
        }.count
        
        return Double(correctWords) / Double(expectedWords.count)
    }
    
    private func analyzeVerses(userInput: String, expectedText: String, verses: [BibleVerse]) -> ([BibleVerse], [BibleVerse]) {
        // 간단한 분석 (실제로는 더 정교한 로직 필요)
        let userWords = userInput.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let expectedWords = expectedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        var correctVerses: [BibleVerse] = []
        var incorrectVerses: [BibleVerse] = []
        
        for verse in verses {
            let verseWords = verse.verseText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            let isCorrect = verseWords.allSatisfy { word in
                expectedWords.contains(word)
            }
            
            if isCorrect {
                correctVerses.append(verse)
            } else {
                incorrectVerses.append(verse)
            }
        }
        
        return (correctVerses, incorrectVerses)
    }
    
    // MARK: - 테스트 결과 관리
    
    func loadTestResults() {
        // SwiftData에서 테스트 결과들을 로드
        // 실제 구현에서는 SwiftData 컨텍스트를 사용
        testResults = []
    }
    
    func saveTestResults() {
        // SwiftData에 테스트 결과들을 저장
        // 실제 구현에서는 SwiftData 컨텍스트를 사용
    }
    
    func getTestResults(for plan: RecitationPlan) -> [TestResult] {
        return testResults.filter { $0.plan.id == plan.id }
    }
    
    func getAverageAccuracy(for plan: RecitationPlan) -> Double {
        let planResults = getTestResults(for: plan)
        guard !planResults.isEmpty else { return 0.0 }
        
        let totalAccuracy = planResults.reduce(0.0) { $0 + $1.accuracy }
        return totalAccuracy / Double(planResults.count)
    }
    
    // MARK: - 테스트 통계
    
    func getTestStatistics(for plan: RecitationPlan) -> TestStatistics {
        let planResults = getTestResults(for: plan)
        
        let totalTests = planResults.count
        let averageAccuracy = getAverageAccuracy(for: plan)
        let bestAccuracy = planResults.map { $0.accuracy }.max() ?? 0.0
        let worstAccuracy = planResults.map { $0.accuracy }.min() ?? 0.0
        
        let dailyTests = planResults.filter { $0.testType == .daily }.count
        let cumulativeTests = planResults.filter { $0.testType == .cumulative }.count
        
        return TestStatistics(
            totalTests: totalTests,
            averageAccuracy: averageAccuracy,
            bestAccuracy: bestAccuracy,
            worstAccuracy: worstAccuracy,
            dailyTests: dailyTests,
            cumulativeTests: cumulativeTests
        )
    }
}

// MARK: - 테스트 세션

class TestSession: ObservableObject {
    let plan: RecitationPlan
    let testType: TestType
    let verses: [BibleVerse]
    
    @Published var currentVerseIndex: Int = 0
    @Published var userInput: String = ""
    @Published var isCompleted: Bool = false
    
    init(plan: RecitationPlan, testType: TestType, verses: [BibleVerse]) {
        self.plan = plan
        self.testType = testType
        self.verses = verses
    }
    
    var currentVerse: BibleVerse? {
        guard currentVerseIndex < verses.count else { return nil }
        return verses[currentVerseIndex]
    }
    
    var progress: Double {
        guard !verses.isEmpty else { return 0.0 }
        return Double(currentVerseIndex) / Double(verses.count)
    }
    
    var isLastVerse: Bool {
        return currentVerseIndex == verses.count - 1
    }
    
    func nextVerse() {
        if currentVerseIndex < verses.count - 1 {
            currentVerseIndex += 1
            userInput = ""
        } else {
            isCompleted = true
        }
    }
    
    func previousVerse() {
        if currentVerseIndex > 0 {
            currentVerseIndex -= 1
            userInput = ""
        }
    }
    
    func getFullText() -> String {
        return verses.map { $0.verseText }.joined(separator: "\n\n")
    }
}

// MARK: - 테스트 통계

struct TestStatistics {
    let totalTests: Int
    let averageAccuracy: Double
    let bestAccuracy: Double
    let worstAccuracy: Double
    let dailyTests: Int
    let cumulativeTests: Int
    
    var accuracyPercentage: String {
        return String(format: "%.1f%%", averageAccuracy * 100)
    }
    
    var bestAccuracyPercentage: String {
        return String(format: "%.1f%%", bestAccuracy * 100)
    }
    
    var worstAccuracyPercentage: String {
        return String(format: "%.1f%%", worstAccuracy * 100)
    }
} 