//
//  ContentView.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

            #if DEBUG
            Text(DefaultEnvironment.debugDescription())
            #endif
        }
        .padding()
        .onAppear {
            #if DEBUG
            print(DefaultEnvironment.debugDescription())
            #endif
        }
    }
}

#Preview {
    ContentView()
}
