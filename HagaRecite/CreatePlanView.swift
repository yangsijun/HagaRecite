import SwiftUI

// MARK: - 계획 생성 화면
struct CreatePlanView: View {
    @EnvironmentObject var planManager: PlanManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedBook: BibleBook?
    @State private var selectedChapter = 1
    @State private var startVerse = 1
    @State private var endVerse = 1
    @State private var selectedVersion = BibleVersion.allVersions[0]
    @State private var targetDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7일 후
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PlanInfoSection(title: $title)
                    BibleRangeSection(
                        selectedBook: $selectedBook,
                        selectedChapter: $selectedChapter,
                        startVerse: $startVerse,
                        endVerse: $endVerse,
                        selectedVersion: $selectedVersion
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
        }
    }
    
    private var canCreatePlan: Bool {
        !title.isEmpty && selectedBook != nil && startVerse <= endVerse
    }
    
    private func createPlan() {
        guard let book = selectedBook else { return }
        
        let startBibleVerse = BibleVerse(
            id: "\(book.code)_\(selectedChapter)_\(startVerse)_\(selectedVersion.code)",
            bookCode: book.code,
            bookName: book.name,
            bookOrder: book.order,
            chapter: selectedChapter,
            verse: startVerse,
            verseText: "", // 실제로는 데이터베이스에서 가져와야 함
            versionCode: selectedVersion.code
        )
        
        let endBibleVerse = BibleVerse(
            id: "\(book.code)_\(selectedChapter)_\(endVerse)_\(selectedVersion.code)",
            bookCode: book.code,
            bookName: book.name,
            bookOrder: book.order,
            chapter: selectedChapter,
            verse: endVerse,
            verseText: "", // 실제로는 데이터베이스에서 가져와야 함
            versionCode: selectedVersion.code
        )
        
        let validation = planManager.validatePlan(startVerse: startBibleVerse, endVerse: endBibleVerse, targetDate: targetDate)
        
        if validation.isValid {
            if planManager.createPlan(title: title, startVerse: startBibleVerse, endVerse: endBibleVerse, targetDate: targetDate) != nil {
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
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var startVerse: Int
    @Binding var endVerse: Int
    @Binding var selectedVersion: BibleVersion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("성경 범위")
                .font(.headline)
                .fontWeight(.semibold)
            
            BookPicker(selectedBook: $selectedBook)
            
            if let book = selectedBook {
                ChapterPicker(selectedChapter: $selectedChapter, book: book)
                VerseRangePicker(startVerse: $startVerse, endVerse: $endVerse)
            }
            
            VersionPicker(selectedVersion: $selectedVersion)
        }
    }
}

// MARK: - 책 선택기
struct BookPicker: View {
    @Binding var selectedBook: BibleBook?
    
    var body: some View {
        Picker("책", selection: $selectedBook) {
            Text("선택하세요").tag(nil as BibleBook?)
            ForEach(BibleBook.allBooks) { book in
                Text(book.name).tag(book as BibleBook?)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

// MARK: - 장 선택기
struct ChapterPicker: View {
    @Binding var selectedChapter: Int
    let book: BibleBook
    
    var body: some View {
        Picker("장", selection: $selectedChapter) {
            ForEach(1...book.chapters, id: \.self) { chapter in
                Text("\(chapter)장").tag(chapter)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

// MARK: - 구절 범위 선택기
struct VerseRangePicker: View {
    @Binding var startVerse: Int
    @Binding var endVerse: Int
    
    var body: some View {
        HStack {
            Picker("시작 구절", selection: $startVerse) {
                ForEach(1...50, id: \.self) { verse in
                    Text("\(verse)절").tag(verse)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Picker("끝 구절", selection: $endVerse) {
                ForEach(1...50, id: \.self) { verse in
                    Text("\(verse)절").tag(verse)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}

// MARK: - 역본 선택기
struct VersionPicker: View {
    @Binding var selectedVersion: BibleVersion
    
    var body: some View {
        Picker("역본", selection: $selectedVersion) {
            ForEach(BibleVersion.allVersions) { version in
                Text(version.name).tag(version)
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
        Button("계획 생성", action: action)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canCreate ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!canCreate)
    }
} 