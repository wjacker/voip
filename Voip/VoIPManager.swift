import Foundation
import AVFoundation
import PJSIP

class VoIPManager: ObservableObject {
    private var endpoint: pjsua_t?
    private var account: pjsua_acc_id?
    private var currentCall: pjsua_call_id?
    private var sipConfig = pjsua_config()
    private var mediaConfig = pjsua_media_config()
    private var transportId: pjsua_transport_id?
    
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
        initializePJSIP()
    }
    
    private func initializePJSIP() {
        var status = pjsua_create()
        guard status == PJ_SUCCESS else {
            print("Error creating PJSUA")
            return
        }
        
        // 配置PJSUA
        pjsua_config_default(&sipConfig)
        pjsua_media_config_default(&mediaConfig)
        
        // 初始化PJSUA
        status = pjsua_init(&sipConfig, &mediaConfig, nil)
        guard status == PJ_SUCCESS else {
            print("Error initializing PJSUA")
            return
        }
        
        // 创建SIP传输
        var transportConfig = pjsua_transport_config()
        pjsua_transport_config_default(&transportConfig)
        transportConfig.port = 5060
        
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &transportConfig, &transportId)
        guard status == PJ_SUCCESS else {
            print("Error creating transport")
            return
        }
        
        // 启动PJSUA
        status = pjsua_start()
        guard status == PJ_SUCCESS else {
            print("Error starting PJSUA")
            return
        }
        
        registerAccount()
    }
    
    private func registerAccount() {
        var accountConfig = pjsua_acc_config()
        pjsua_acc_config_default(&accountConfig)
        
        let idUri = "sip:\(username)@\(sipDomain)"
        let regUri = "sip:\(sipDomain)"
        
        accountConfig.id = pj_str(idUri)
        accountConfig.reg_uri = pj_str(regUri)
        accountConfig.cred_count = 1
        accountConfig.cred_info.0.realm = pj_str("*")
        accountConfig.cred_info.0.scheme = pj_str("digest")
        accountConfig.cred_info.0.username = pj_str(username)
        accountConfig.cred_info.0.data_type = PJSIP_CRED_DATA_PLAIN_PASSWD
        accountConfig.cred_info.0.data = pj_str(password)
        
        var accId: pjsua_acc_id = -1
        let status = pjsua_acc_add(&accountConfig, PJ_TRUE, &accId)
        
        if status == PJ_SUCCESS {
            self.account = accId
            DispatchQueue.main.async {
                self.isRegistered = true
            }
        } else {
            print("Error registering account")
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
        
        let destUri = "sip:\(recipient)@\(sipDomain)"
        var callId: pjsua_call_id = -1
        
        let status = pjsua_call_make_call(account!, pj_str(destUri), 0, nil, nil, &callId)
        
        if status == PJ_SUCCESS {
            currentCall = callId
            isInCall = true
            startCallTimer()
        } else {
            print("Error making call")
        }
    }
    
    func endCall() {
        guard isInCall, let callId = currentCall else { return }
        
        let status = pjsua_call_hangup(callId, 200, nil, nil)
        if status == PJ_SUCCESS {
            currentCall = nil
            isInCall = false
            stopCallTimer()
        } else {
            print("Error hanging up call")
        }
    }
    
    deinit {
        if let callId = currentCall {
            pjsua_call_hangup(callId, 200, nil, nil)
        }
        pjsua_destroy()
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