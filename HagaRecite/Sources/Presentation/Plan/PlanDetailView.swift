import SwiftUI

struct PlanDetailView: View {
    let plan: RecitationPlan
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 플랜 기본 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.title)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(plan.bibleRange?.displayName ?? "성경 범위")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("진행률: \(Int(plan.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("D-\(plan.daysRemaining)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 날짜별 암송 구절 리스트
                VStack(alignment: .leading, spacing: 16) {
                    Text("일별 암송 구절")
                        .font(.headline)
                        .fontWeight(.semibold)
                    ForEach(plan.dailyVerses.sorted(by: { $0.date < $1.date }), id: \.id) { dailyVerse in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(dailyVerse.date, style: .date)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if dailyVerse.isCompleted {
                                    Text("완료")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            Text(dailyVerse.reference)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            // 각 절별로 절 번호와 구절 표시
                            ForEach(dailyVerse.verses, id: \.id) { verse in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("\(verse.verse)절")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.accentColor)
                                    Text(verse.verseText)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("계획 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
} 