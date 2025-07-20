import SwiftUI

// MARK: - 계획 생성 화면
struct CreatePlanView: View {
    @EnvironmentObject var planManager: PlanManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    // 시작 구절
    @State private var startBook: BibleBook?
    @State private var startChapter = 1
    @State private var startVerse = 1
    // 끝 구절
    @State private var endBook: BibleBook?
    @State private var endChapter = 1
    @State private var endVerse = 1
    @State private var selectedVersion: BibleVersion?
    @State private var targetDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7일 후
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 데이터베이스에서 가져온 데이터
    @State private var availableBooks: [BibleBook] = []
    @State private var availableVersions: [BibleVersion] = []
    @State private var maxStartChapter = 1
    @State private var maxEndChapter = 1
    @State private var maxStartVerse = 1
    @State private var maxEndVerse = 1
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PlanInfoSection(title: $title)
                    BibleRangeSection(
                        startBook: $startBook,
                        startChapter: $startChapter,
                        startVerse: $startVerse,
                        endBook: $endBook,
                        endChapter: $endChapter,
                        endVerse: $endVerse,
                        selectedVersion: $selectedVersion,
                        availableBooks: availableBooks,
                        availableVersions: availableVersions,
                        maxStartChapter: maxStartChapter,
                        maxEndChapter: maxEndChapter,
                        maxStartVerse: maxStartVerse,
                        maxEndVerse: maxEndVerse
                    )
                    TargetDateSection(targetDate: $targetDate)
                    CreateButton(
                        canCreate: canCreatePlan,
                        action: createPlan
                    )
                }
                .padding()
            }
            .navigationTitle("새 계획")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .alert("오류", isPresented: $showingAlert) {
                Button("확인") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadData()
            }
            .onChange(of: selectedVersion) { _, _ in
                loadBooksForVersion()
            }
            .onChange(of: startBook) { _, _ in
                updateStartChapterAndVerse()
            }
            .onChange(of: endBook) { _, _ in
                updateEndChapterAndVerse()
            }
            .onChange(of: startChapter) { _, _ in
                updateStartVerse()
            }
            .onChange(of: endChapter) { _, _ in
                updateEndVerse()
            }
        }
    }
    
    private var canCreatePlan: Bool {
        !title.isEmpty && startBook != nil && endBook != nil && selectedVersion != nil && (startBook!.order < endBook!.order || (startBook!.order == endBook!.order && (startChapter < endChapter || (startChapter == endChapter && startVerse <= endVerse))))
    }
    
    private func loadData() {
        let defaultVersion = BibleDatabase.shared.getAllVersions().first
        selectedVersion = defaultVersion
        loadBooksForVersion()
        availableVersions = BibleDatabase.shared.getAllVersions()
    }
    
    private func loadBooksForVersion() {
        guard let version = selectedVersion else { return }
        availableBooks = BibleDatabase.shared.getAllBooks(versionCode: version.code)
        if let firstBook = availableBooks.first {
            startBook = firstBook
            endBook = firstBook
        }
    }
    
    private func updateStartChapterAndVerse() {
        guard let book = startBook else { return }
        maxStartChapter = BibleDatabase.shared.getChaptersForBook(bookCode: book.code, versionCode: selectedVersion?.code ?? "KRV")
        startChapter = 1
        updateStartVerse()
    }
    private func updateEndChapterAndVerse() {
        guard let book = endBook else { return }
        maxEndChapter = BibleDatabase.shared.getChaptersForBook(bookCode: book.code, versionCode: selectedVersion?.code ?? "KRV")
        endChapter = 1
        updateEndVerse()
    }
    private func updateStartVerse() {
        guard let book = startBook else { return }
        maxStartVerse = BibleDatabase.shared.getVersesForChapter(bookCode: book.code, chapter: startChapter, versionCode: selectedVersion?.code ?? "KRV")
        startVerse = 1
    }
    private func updateEndVerse() {
        guard let book = endBook else { return }
        maxEndVerse = BibleDatabase.shared.getVersesForChapter(bookCode: book.code, chapter: endChapter, versionCode: selectedVersion?.code ?? "KRV")
        endVerse = 1
    }
    
    private func createPlan() {
        guard let sBook = startBook, let eBook = endBook, let version = selectedVersion else { return }
        let startBibleVerse = BibleDatabase.shared.getVerse(
            bookCode: sBook.code,
            chapter: startChapter,
            verse: startVerse,
            versionCode: version.code
        )
        let endBibleVerse = BibleDatabase.shared.getVerse(
            bookCode: eBook.code,
            chapter: endChapter,
            verse: endVerse,
            versionCode: version.code
        )
        guard let startVerseObj = startBibleVerse, let endVerseObj = endBibleVerse else {
            alertMessage = "선택한 구절을 찾을 수 없습니다."
            showingAlert = true
            return
        }
        let validation = planManager.validatePlan(startVerse: startVerseObj, endVerse: endVerseObj, targetDate: targetDate)
        if validation.isValid {
            if planManager.createPlan(title: title, startVerse: startVerseObj, endVerse: endVerseObj, targetDate: targetDate) != nil {
                dismiss()
            } else {
                alertMessage = "계획 생성에 실패했습니다."
                showingAlert = true
            }
        } else {
            alertMessage = validation.errorMessage ?? "알 수 없는 오류가 발생했습니다."
            showingAlert = true
        }
    }
}

// MARK: - 계획 정보 섹션
struct PlanInfoSection: View {
    @Binding var title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("계획 정보")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("계획 제목", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// MARK: - 성경 범위 섹션
struct BibleRangeSection: View {
    @Binding var startBook: BibleBook?
    @Binding var startChapter: Int
    @Binding var startVerse: Int
    @Binding var endBook: BibleBook?
    @Binding var endChapter: Int
    @Binding var endVerse: Int
    @Binding var selectedVersion: BibleVersion?
    let availableBooks: [BibleBook]
    let availableVersions: [BibleVersion]
    let maxStartChapter: Int
    let maxEndChapter: Int
    let maxStartVerse: Int
    let maxEndVerse: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("성경 범위")
                .font(.headline)
                .fontWeight(.semibold)
            VersionPicker(selectedVersion: $selectedVersion, availableVersions: availableVersions)
            HStack {
                VStack(alignment: .leading) {
                    Text("시작 구절")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    BookPicker(selectedBook: $startBook, availableBooks: availableBooks)
                    ChapterPicker(selectedChapter: $startChapter, maxChapter: maxStartChapter)
                    VerseRangePicker(startVerse: $startVerse, endVerse: $endVerse, maxVerses: maxStartVerse, isStart: true)
                }
                Spacer(minLength: 24)
                VStack(alignment: .leading) {
                    Text("끝 구절")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    BookPicker(selectedBook: $endBook, availableBooks: availableBooks)
                    ChapterPicker(selectedChapter: $endChapter, maxChapter: maxEndChapter)
                    VerseRangePicker(startVerse: $startVerse, endVerse: $endVerse, maxVerses: maxEndVerse, isStart: false)
                }
            }
        }
    }
}

// MARK: - 책 선택기
struct BookPicker: View {
    @Binding var selectedBook: BibleBook?
    let availableBooks: [BibleBook]
    
    var body: some View {
        Picker("책", selection: $selectedBook) {
            Text("선택하세요").tag(nil as BibleBook?)
            ForEach(availableBooks) { book in
                Text(book.name).tag(book as BibleBook?)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

// MARK: - ChapterPicker, VerseRangePicker 수정
struct ChapterPicker: View {
    @Binding var selectedChapter: Int
    var maxChapter: Int
    var body: some View {
        Picker("장", selection: $selectedChapter) {
            ForEach(1...maxChapter, id: \.self) { chapter in
                Text("\(chapter)장").tag(chapter)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

struct VerseRangePicker: View {
    @Binding var startVerse: Int
    @Binding var endVerse: Int
    var maxVerses: Int
    var isStart: Bool = true
    var body: some View {
        Picker(isStart ? "절" : "절", selection: isStart ? $startVerse : $endVerse) {
            ForEach(1...maxVerses, id: \.self) { verse in
                Text("\(verse)절").tag(verse)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

// MARK: - 역본 선택기
struct VersionPicker: View {
    @Binding var selectedVersion: BibleVersion?
    let availableVersions: [BibleVersion]
    
    var body: some View {
        Picker("역본", selection: $selectedVersion) {
            Text("선택하세요").tag(nil as BibleVersion?)
            ForEach(availableVersions) { version in
                Text(version.name).tag(version as BibleVersion?)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

// MARK: - 목표 날짜 섹션
struct TargetDateSection: View {
    @Binding var targetDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("목표 날짜")
                .font(.headline)
                .fontWeight(.semibold)
            
            DatePicker("완료 목표일", selection: $targetDate, displayedComponents: .date)
        }
    }
}

// MARK: - 생성 버튼
struct CreateButton: View {
    let canCreate: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("계획 생성")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, minHeight: 36)
                .padding(.vertical, 8)
                .background(canCreate ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(!canCreate)
        .padding(.top, 16)
    }
} 
