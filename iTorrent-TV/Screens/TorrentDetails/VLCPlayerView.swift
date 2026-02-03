//
//  VLCPlayerView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 12.12.2025.
//

import SwiftUI
import UIKit
import VLCKit

struct VLCPlayerView: View {
    let url: URL
    var body: some View {
        VLCPlayerViewRepresentable(url: url)
            .ignoresSafeArea()
            .background(Color.black)
    }
}

struct VLCPlayerViewRepresentable: UIViewRepresentable {
    var url: URL
    @State var mediaPlayer = VLCMediaPlayer()

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        mediaPlayer.drawable = view
        mediaPlayer.media = VLCMedia(url: url)
        mediaPlayer.play()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
