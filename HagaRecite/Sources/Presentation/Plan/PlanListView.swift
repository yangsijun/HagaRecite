//
//  PlanListView.swift
//  HagaRecite
//
//  Created by 양시준 on 7/20/25.
//

import SwiftUI

// MARK: - 계획 목록 화면
struct PlanListView: View {
    @EnvironmentObject var planManager: PlanManager
    @State private var showingCreatePlan = false
    @State private var selectedPlan: RecitationPlan?
    
    var body: some View {
        NavigationStack {
            List {
                if planManager.plans.isEmpty {
                    VStack(spacing: 8) {
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
                            .onTapGesture {
                                selectedPlan = plan
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deletePlans)
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
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
            .navigationDestination(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
        }
    }
    
    private func deletePlans(offsets: IndexSet) {
        for index in offsets {
            planManager.deletePlan(planManager.plans[index])
        }
    }
}

// RecitationPlan이 Identifiable을 준수하도록 확장 (필요시)
extension RecitationPlan: Identifiable {}
