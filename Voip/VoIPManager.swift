import Foundation
import AVFoundation
import linphonesw

class VoIPManager: ObservableObject {
    private var core: Core?
    private var account: Account?
    private var currentCall: Call?
    private let factory = Factory.Instance()
    
    // SIP账户配置 - 请替换为您的实际SIP服务器信息
    private let sipDomain = "sip.example.com"    // 替换为您的SIP服务器域名
    private let username = "your_sip_username" // 替换为您的SIP账户用户名
    private let password = "your_sip_password" // 替换为您的SIP账户密码
    @Published var isRegistered = false
    @Published var isInCall = false
    @Published var currentCallDuration: TimeInterval = 0
    
    private var audioSession: AVAudioSession?
    private var timer: Timer?
    
    init() {
        setupAudioSession()
        initializeLinphone()
    }
    
    private func initializeLinphone() {
        do {
            try factory.start()
            core = try factory.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
            try core?.start()
            
            // 配置SIP传输
            let transports = try factory.createTransports()
            transports.udpPort = 5060
            try core?.setTransports(transports)
            
            registerAccount()
        } catch {
            print("Error initializing Linphone: \(error)")
        }
    }
    
    private func registerAccount() {
        do {
            let authInfo = try factory.createAuthInfo(username: username, userid: username, passwd: password, ha1: "", realm: "*", domain: sipDomain)
            try core?.addAuthInfo(authInfo)
            
            let accountParams = try core?.createAccountParams()
            try accountParams?.setIdentityAddress(try factory.createAddress(addr: "sip:\(username)@\(sipDomain)"))
            try accountParams?.setServerAddress(try factory.createAddress(addr: "sip:\(sipDomain)"))
            try accountParams?.setRegisterEnabled(true)
            
            account = try core?.createAccount(params: accountParams!)
            try account?.addListener { [weak self] account, state, message in
                DispatchQueue.main.async {
                    self?.isRegistered = state == .Ok
                }
            }
        } catch {
            print("Error registering account: \(error)")
        }
    }
    
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playAndRecord, mode: .voiceChat, options: [])
            try audioSession?.setActive(true)
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    func startCall(to recipient: String) {
        guard !isInCall, isRegistered else { return }
        
        do {
            let address = try factory.createAddress(addr: "sip:\(recipient)@\(sipDomain)")
            currentCall = try core?.inviteAddress(addr: address)
            try currentCall?.addListener { [weak self] call, state, message in
                if state == .Connected {
                    DispatchQueue.main.async {
                        self?.isInCall = true
                        self?.startCallTimer()
                    }
                }
            }
        } catch {
            print("Error making call: \(error)")
        }
    }
    
    func endCall() {
        guard isInCall, let call = currentCall else { return }
        
        do {
            try call.terminate()
            currentCall = nil
            isInCall = false
            stopCallTimer()
        } catch {
            print("Error hanging up call: \(error)")
        }
    }
    
    deinit {
        if let call = currentCall {
            try? call.terminate()
        }
        core?.stop()
        core = nil
        try? factory.stop()
    }
    
    private func startCallTimer() {
        currentCallDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentCallDuration += 1
        }
    }
    
    private func stopCallTimer() {
        timer?.invalidate()
        timer = nil
        currentCallDuration = 0
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}