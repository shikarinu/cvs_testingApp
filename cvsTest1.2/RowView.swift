//
//  RowView.swift
//  cvsTest1.2
//
//  Created by ISHII TOSHIHIKO on 2024/06/15.
//

import SwiftUI

struct RowView: View {
    
    var photo:PhotoData
    
    var body: some View {
        HStack{
            Image(photo.imageName)
                .resizable()
                .frame(width: 60, height: 60)
        }
    }
}

#Preview {
    RowView()
}
