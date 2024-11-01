//
//  Styles.swift
//  Whether
//
//  Created by Ben Davis on 10/24/24.
//

import Foundation
import SwiftUI
struct TransparentGroupBox: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            HStack {
                configuration.label
                    .font(.headline)
                    .foregroundStyle(.black.opacity(0.75))
                   

                
            }.frame(maxWidth: .infinity, alignment: .leading)
//                .background {
//                    RoundedRectangle(cornerRadius: 4)
//                        .foregroundStyle(.ultraThinMaterial)
//                }
            
            configuration.content
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(.ultraThinMaterial)
        }
    }
}



#Preview {
    GroupBox("Wind") {
        Text("Test preview of transparant group box")
    }
    .groupBoxStyle(TransparentGroupBox())
}



//struct TransparentGroupBox: GroupBoxStyle {
//    func makeBody(configuration: Configuration) -> some View {
//            
//            
//            configuration.content
//                .frame(maxWidth: .infinity)
//                .padding(EdgeInsets(top: 24, leading: 8, bottom: 8, trailing: 8))
//                .background(RoundedRectangle(cornerRadius: 8).foregroundStyle(.ultraThinMaterial))
//                .overlay(alignment: .topLeading) {
//                    configuration.label
//                        .font(.system(.callout, design: .rounded, weight: .bold))
//                        .foregroundStyle(.secondary)
//                        .background {
//                            RoundedRectangle(cornerRadius: 4)
//                                .foregroundStyle(.black.opacity(0.20))
//                        }
//                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
//
//                }
//
//        
//        //            .overlay(configuration.label
////                .padding(.leading, 8)
////                .font(.system(.callout, design: .rounded, weight: .bold))
////                .foregroundStyle(.secondary)
////                     , alignment: .topLeading)
//    }
//}
