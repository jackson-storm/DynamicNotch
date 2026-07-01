//
//  SleekMiniGraphView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/1/26.
//

import SwiftUI

struct SleekMiniGraphView: View {
    var history: [Double]
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            let points = normalizedPoints(in: geometry.size)
            
            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        for pt in points {
                            path.addLine(to: pt)
                        }
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for pt in points.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .frame(height: 28)
    }
    
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard history.count > 1 else { return [] }
        let stepX = size.width / CGFloat(history.count - 1)
        
        let maxVal = max(history.max() ?? 0.0, 20.0)
        
        return history.enumerated().map { index, val in
            let x = CGFloat(index) * stepX
            let normalizedY = CGFloat(val / maxVal)
            let y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1)
            return CGPoint(x: x, y: y)
        }
    }
}
