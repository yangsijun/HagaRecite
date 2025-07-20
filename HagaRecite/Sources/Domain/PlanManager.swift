import Foundation
import SwiftData

@MainActor
class PlanManager: ObservableObject {
    @Published var plans: [RecitationPlan] = []
    @Published var currentPlan: RecitationPlan?
    @Published var todayVerses: [DailyVerse] = []
    
    private let bibleDatabase = BibleDatabase.shared
    private var context: ModelContext?
    
    // context를 외부에서 주입
    func setContext(_ context: ModelContext) {
        self.context = context
        fetchPlans()
    }
    
    // MARK: - 계획 생성
    func createPlan(title: String, startVerse: BibleVerse, endVerse: BibleVerse, targetDate: Date) -> RecitationPlan? {
        guard let context = context else { return nil }
        let startDate = Date()
        let plan = RecitationPlan(
            title: title,
            startVerse: startVerse,
            endVerse: endVerse,
            startDate: startDate,
            targetDate: targetDate
        )
        // 일별 구절 분배
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 1
        let verses = bibleDatabase.getVersesInRange(startVerse: startVerse, endVerse: endVerse, versionCode: startVerse.versionCode)
        if verses.isEmpty {
            return nil
        }
        let versesPerDay = max(1, verses.count / totalDays)
        let remainingVerses = verses.count % totalDays
        var currentVerseIndex = 0
        for day in 0..<totalDays {
            let dayDate = Calendar.current.date(byAdding: .day, value: day, to: startDate) ?? startDate
            let versesForThisDay = versesPerDay + (day < remainingVerses ? 1 : 0)
            let dayVerses = Array(verses[currentVerseIndex..<min(currentVerseIndex + versesForThisDay, verses.count)])
            let dailyVerse = DailyVerse(date: dayDate, verses: dayVerses, plan: plan)
            plan.dailyVerses.append(dailyVerse)
            context.insert(dailyVerse)
            currentVerseIndex += versesForThisDay
            if currentVerseIndex >= verses.count {
                break
            }
        }
        context.insert(plan)
        fetchPlans()
        return plan
    }
    
    // MARK: - 계획 관리
    func fetchPlans() {
        guard let context = context else { return }
        let descriptor = FetchDescriptor<RecitationPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let result = try? context.fetch(descriptor) {
            plans = result
        }
    }
    
    func deletePlan(_ plan: RecitationPlan) {
        guard let context = context else { return }
        context.delete(plan)
        fetchPlans()
    }
    
    func markDayAsCompleted(_ dailyVerse: DailyVerse) {
        dailyVerse.isCompleted = true
        dailyVerse.completedAt = Date()
        saveContext()
    }
    
    func markDayAsIncomplete(_ dailyVerse: DailyVerse) {
        dailyVerse.isCompleted = false
        dailyVerse.completedAt = nil
        saveContext()
    }
    
    private func saveContext() {
        guard let context = context else { return }
        do {
            try context.save()
        } catch {
            print("SwiftData 저장 실패: \(error)")
        }
        fetchPlans()
    }
    
    // MARK: - 오늘의 암송 구절
    func loadTodayVerses() {
        let today = Date()
        todayVerses = []
        for plan in plans {
            if let todayVerse = plan.dailyVerses.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: today)
            }) {
                todayVerses.append(todayVerse)
            }
        }
    }
    func getTodayVerses() -> [DailyVerse] {
        let today = Date()
        var todayVerses: [DailyVerse] = []
        for plan in plans {
            if let todayVerse = plan.dailyVerses.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: today)
            }) {
                todayVerses.append(todayVerse)
            }
        }
        return todayVerses
    }
    // MARK: - 진행률 계산
    func getOverallProgress() -> Double {
        guard !plans.isEmpty else { return 0.0 }
        let totalProgress = plans.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(plans.count)
    }
    func getPlanProgress(_ plan: RecitationPlan) -> Double {
        return plan.progress
    }
    // MARK: - 계획 검증
    func validatePlan(startVerse: BibleVerse, endVerse: BibleVerse, targetDate: Date) -> PlanValidationResult {
        let startDate = Date()
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 1
        if totalDays <= 0 {
            return .invalidDate("목표 날짜는 오늘 이후여야 합니다.")
        }
        let verses = bibleDatabase.getVersesInRange(startVerse: startVerse, endVerse: endVerse, versionCode: startVerse.versionCode)
        if verses.isEmpty {
            return .invalidRange("선택한 범위에 성경 구절이 없습니다.")
        }
        let versesPerDay = Double(verses.count) / Double(totalDays)
        
        if versesPerDay > 10 {
            return .tooManyVerses("일일 암송량이 너무 많습니다. 기간을 늘리거나 범위를 줄여주세요.")
        }
        return .valid
    }
}

// MARK: - 계획 검증 결과

enum PlanValidationResult {
    case valid
    case invalidDate(String)
    case invalidRange(String)
    case tooManyVerses(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        default:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalidDate(let message):
            return message
        case .invalidRange(let message):
            return message
        case .tooManyVerses(let message):
            return message
        }
    }
} 
