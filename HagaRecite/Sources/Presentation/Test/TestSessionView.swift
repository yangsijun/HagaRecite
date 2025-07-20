//
//  TestSessionView.swift
//  HagaRecite
//bl
//  Created by 양시준 on 7/20/25.
//

import SwiftUI

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
