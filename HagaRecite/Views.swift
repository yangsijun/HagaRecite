import SwiftUI

// MARK: - 계획 목록 화면
struct PlanListView: View {
    @EnvironmentObject var planManager: PlanManager
    @State private var showingCreatePlan = false
    
    var body: some View {
        NavigationView {
            List {
                if planManager.plans.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("암송 계획이 없습니다")
                            .font(.headline)
                        Text("새로운 계획을 만들어보세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(planManager.plans, id: \.id) { plan in
                        PlanCard(plan: plan)
                            .environmentObject(planManager)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deletePlans)
                }
            }
            .navigationTitle("암송 계획")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePlan = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreatePlanView()
                    .environmentObject(planManager)
            }
        }
    }
    
    private func deletePlans(offsets: IndexSet) {
        for index in offsets {
            planManager.deletePlan(planManager.plans[index])
        }
    }
}

// MARK: - 테스트 화면
struct TestView: View {
    @EnvironmentObject var testManager: TestManager
    @EnvironmentObject var planManager: PlanManager
    @State private var selectedPlan: RecitationPlan?
    @State private var selectedTestType: TestType = .daily
    @State private var showingTest = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if planManager.plans.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("테스트할 계획이 없습니다")
                            .font(.headline)
                        Text("암송 계획을 먼저 만들어보세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 20) {
                        // 계획 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("테스트할 계획 선택")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(planManager.plans, id: \.id) { plan in
                                PlanCard(plan: plan)
                                    .environmentObject(planManager)
                                    .onTapGesture {
                                        selectedPlan = plan
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedPlan?.id == plan.id ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                        
                        // 테스트 타입 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("테스트 타입")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("테스트 타입", selection: $selectedTestType) {
                                ForEach(TestType.allCases, id: \.self) { testType in
                                    Text(testType.displayName).tag(testType)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // 테스트 시작 버튼
                        Button(action: {
                            if selectedPlan != nil {
                                showingTest = true
                            }
                        }) {
                            Text("테스트 시작")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedPlan != nil ? Color.blue : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(selectedPlan == nil)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("암송 테스트")
            .sheet(isPresented: $showingTest) {
                if let plan = selectedPlan {
                    TestSessionView(plan: plan, testType: selectedTestType)
                        .environmentObject(testManager)
                }
            }
        }
    }
}

// MARK: - 테스트 세션 화면
struct TestSessionView: View {
    let plan: RecitationPlan
    let testType: TestType
    @EnvironmentObject var testManager: TestManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var testSession: TestSession?
    @State private var showingResults = false
    @State private var testResult: TestResult?
    
    var body: some View {
        NavigationView {
            VStack {
                if let session = testSession {
                    TestContentView(session: session) { result in
                        testResult = result
                        showingResults = true
                    }
                    .environmentObject(testManager)
                } else {
                    ProgressView("테스트 준비 중...")
                }
            }
            .navigationTitle("\(testType.displayName) 테스트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        testManager.endTest()
                        dismiss()
                    }
                }
            }
            .onAppear {
                testSession = testManager.startTest(plan: plan, testType: testType)
            }
            .sheet(isPresented: $showingResults) {
                if let result = testResult {
                    TestResultView(result: result)
                }
            }
        }
    }
}

// MARK: - 테스트 콘텐츠 뷰
struct TestContentView: View {
    @ObservedObject var session: TestSession
    @EnvironmentObject var testManager: TestManager
    let onComplete: (TestResult) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 진행률
            VStack(spacing: 8) {
                ProgressView(value: session.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                Text("\(Int(session.progress * 100))% 완료")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 현재 구절
            if let currentVerse = session.currentVerse {
                VStack(spacing: 16) {
                    Text(currentVerse.reference)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("구절을 암송해보세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $session.userInput)
                        .frame(minHeight: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding()
            }
            
            // 네비게이션 버튼
            HStack(spacing: 20) {
                Button("이전") {
                    session.previousVerse()
                }
                .disabled(session.currentVerseIndex == 0)
                
                Spacer()
                
                Button(session.isLastVerse ? "완료" : "다음") {
                    if session.isLastVerse {
                        completeTest()
                    } else {
                        session.nextVerse()
                    }
                }
                .disabled(session.userInput.isEmpty)
            }
            .padding()
        }
    }
    
    private func completeTest() {
        let result = testManager.submitTestResult(
            userInput: session.userInput,
            expectedText: session.getFullText(),
            verses: session.verses
        )
        onComplete(result)
    }
}

// MARK: - 테스트 결과 화면
struct TestResultView: View {
    let result: TestResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 결과 요약
                    VStack(spacing: 16) {
                        Text("테스트 완료!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("정확도: \(Int(result.accuracy * 100))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(result.accuracy >= 0.8 ? .green : .orange)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(result.totalVerses)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("전체 구절")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(result.correctVerses)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("정답")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(result.incorrectVerseIds.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                Text("오답")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 오답 구절들
                    if !result.incorrectVerseIds.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("틀린 구절들")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(result.incorrectVerseIds, id: \.self) { verseId in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("구절 ID: \(verseId)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("구절 내용")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("테스트 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 설정 화면
struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("개발자")
                        Spacer()
                        Text("HagaRecite Team")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("지원") {
                    Button("사용법 가이드") {
                        // 사용법 가이드 표시
                    }
                    
                    Button("피드백 보내기") {
                        // 피드백 기능
                    }
                    
                    Button("개인정보 처리방침") {
                        // 개인정보 처리방침 표시
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
} 