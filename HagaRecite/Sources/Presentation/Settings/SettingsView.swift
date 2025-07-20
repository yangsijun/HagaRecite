//
//  SettingsView.swift
//  HagaRecite
//
//  Created by 양시준 on 7/20/25.
//

import SwiftUI

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
                        Text("Yang Sijun")
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
