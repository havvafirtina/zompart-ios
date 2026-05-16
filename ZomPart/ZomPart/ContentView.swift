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

            Text(DefaultEnvironment.debugDescription())
        }
        .padding()
        .onAppear {
            print(DefaultEnvironment.debugDescription())
        }
    }
}

#Preview {
    ContentView()
}
