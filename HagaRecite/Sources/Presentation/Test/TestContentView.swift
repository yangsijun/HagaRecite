//
//  TestContentView.swift
//  HagaRecite
//
//  Created by 양시준 on 7/20/25.
//

import SwiftUI

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
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
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
                    
                    TextEditor(text: Binding(
                        get: { session.currentUserInput },
                        set: { session.currentUserInput = $0 }
                    ))
                    .frame(minHeight: 100)
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
                .disabled(session.currentUserInput.isEmpty)
            }
            .padding()
        }
    }
    
    private func completeTest() {
        let result = testManager.submitTestResult(
            userInput: session.getFullText(),
            expectedText: session.verses.map { $0.verseText }.joined(separator: "\n"),
            verses: session.verses
        )
        onComplete(result)
    }
}
