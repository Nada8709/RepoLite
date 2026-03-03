//
//  ContentView.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
                .onTapGesture {
                    print(Bundle.main.object(forInfoDictionaryKey: "GITHUB_CLIENT_ID") as? String ?? "NOT FOUND")
                }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
