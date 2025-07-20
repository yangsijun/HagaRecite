//
//  TestResultView.swift
//  HagaRecite
//
//  Created by 양시준 on 7/20/25.
//

import SwiftUI

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
                            
                            ForEach(result.incorrectVerses, id: \.id) { verse in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(verse.reference)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("정답:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        HighlightedVerseText(
                                            verse: verse,
                                            diffs: result.verseMistakes[verse.id] ?? []
                                        )
                                    }
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

// MARK: - 틀린 단어 하이라이트 뷰
struct HighlightedVerseText: View {
    let verse: BibleVerse
    let diffs: [DiffResult]

    var body: some View {
        diffs.reduce(Text("")) { partial, diff in
            let t: Text
            switch diff.type {
            case .correct:
                t = Text(diff.word)
            case .inserted:
                t = Text(diff.word).foregroundColor(.red).strikethrough()
            case .deleted:
                t = Text(diff.word).foregroundColor(.gray).italic()
            }
            return partial + t
        }
        .font(.body)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
