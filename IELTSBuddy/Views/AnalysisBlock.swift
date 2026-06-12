//
//  AnalysisBlock.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 3/6/2026.
//

import SwiftUI

struct AnalysisBlock: View {
    let title: String
    let items: [String]
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(color.opacity(0.7))
                            .padding(.top, 6)
                        
                        Text(item)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.appTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
