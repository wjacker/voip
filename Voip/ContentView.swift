//
//  ContentView.swift
//  Voip
//
//  Created by Jack on 2025/3/4.
//

import SwiftUI
import linphonesw

struct ContentView: View {
    @StateObject private var voipManager = VoIPManager()
    @State private var phoneNumber = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("VoIP电话")
                .font(.largeTitle)
                .padding()
            
            TextField("输入电话号码", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .padding(.horizontal)
            
            if voipManager.isInCall {
                VStack(spacing: 10) {
                    Text("通话中...")
                        .font(.headline)
                    Text(voipManager.formatDuration(voipManager.currentCallDuration))
                        .font(.title)
                        .monospacedDigit()
                    
                    Button(action: {
                        voipManager.endCall()
                    }) {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
            } else {
                Button(action: {
                    guard !phoneNumber.isEmpty else { return }
                    voipManager.startCall(to: phoneNumber)
                }) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
}

#Preview {
    ContentView()
}
