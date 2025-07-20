//
//  TestView.swift
//  HagaRecite
//
//  Created by 양시준 on 7/20/25.
//

import SwiftUI

// MARK: - 테스트 화면
struct TestView: View {
    @EnvironmentObject var testManager: TestManager
    @EnvironmentObject var planManager: PlanManager
    @State private var selectedPlan: RecitationPlan?
    @State private var selectedTestType: TestType = .daily
    @State private var showingTest = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
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
                                                .stroke(selectedPlan?.id == plan.id ? Color.accentColor : Color.clear, lineWidth: 2)
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
                                    .background(selectedPlan != nil ? Color.accentColor : Color.gray)
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
}
