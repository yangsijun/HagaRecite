import SwiftUI

// MARK: - 홈 화면
struct HomeView: View {
    @EnvironmentObject var planManager: PlanManager
    @EnvironmentObject var testManager: TestManager
    @State private var showingCreatePlan = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더
                    headerSection
                    
                    // 오늘의 암송
                    todaySection
                    
                    // 진행 중인 계획
                    activePlansSection
                    
                    // 빠른 액션
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Haga 암송")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePlan = true }) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreatePlanView()
                    .environmentObject(planManager)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("오늘도 말씀 암송을 시작해보세요")
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text("하나님의 말씀을 마음에 새기며")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("오늘의 암송")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if planManager.todayVerses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("오늘 암송할 구절이 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("새로운 계획을 만들어보세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                ForEach(planManager.todayVerses, id: \.id) { dailyVerse in
                    TodayVerseCard(dailyVerse: dailyVerse)
                        .environmentObject(planManager)
                }
            }
        }
    }
    
    private var activePlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("진행 중인 계획")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if planManager.plans.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("진행 중인 계획이 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                ForEach(planManager.plans.prefix(3), id: \.id) { plan in
                    PlanCard(plan: plan)
                        .environmentObject(planManager)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("빠른 액션")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "새 계획",
                    subtitle: "암송 계획 만들기",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingCreatePlan = true
                }
                
                QuickActionCard(
                    title: "테스트",
                    subtitle: "암송 테스트",
                    icon: "checkmark.circle.fill",
                    color: .green
                ) {
                    // 테스트 화면으로 이동
                }
            }
        }
    }
}

// MARK: - 오늘의 암송 카드
struct TodayVerseCard: View {
    let dailyVerse: DailyVerse
    @EnvironmentObject var planManager: PlanManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dailyVerse.reference)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    if dailyVerse.isCompleted {
                        planManager.markDayAsIncomplete(dailyVerse)
                    } else {
                        planManager.markDayAsCompleted(dailyVerse)
                    }
                }) {
                    Image(systemName: dailyVerse.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(dailyVerse.isCompleted ? .green : .gray)
                        .font(.title2)
                }
            }
            
            Text(dailyVerse.displayText)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(dailyVerse.verseIds.count)구절")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 계획 카드
struct PlanCard: View {
    let plan: RecitationPlan
    @EnvironmentObject var planManager: PlanManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(plan.daysRemaining)일 남음")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(plan.bibleRange?.displayName ?? "성경 범위")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: plan.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("\(Int(plan.progress * 100))% 완료")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("D-\(plan.daysRemaining)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 빠른 액션 카드
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}