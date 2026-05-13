//
//  RecommendedTopicCard.swift
//  IELTSBuddy
//

import SwiftUI

struct RecommendedTopicCard: View {
    let item: RecommendedTopicItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.emoji)
                .font(.title)
            Text(item.topicTitle)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(item.partLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 148, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
