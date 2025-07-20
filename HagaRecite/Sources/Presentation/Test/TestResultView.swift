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
                                    Text(verse.verseText)
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
