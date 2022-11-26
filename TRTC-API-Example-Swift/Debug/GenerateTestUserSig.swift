/*
 * Module:   GenerateTestUserSig
 *
 * Function: 用于生成测试用的 UserSig，UserSig 是腾讯云为其云服务设计的一种安全保护签名。
 *           其计算方法是对 SDKAppID、UserID 和 EXPIRETIME 进行加密，加密算法为 HMAC-SHA256。
 *
 * Attention: 请不要将如下代码发布到您的线上正式版本的 App 中，原因如下：
 *
 *            本文件中的代码虽然能够正确计算出 UserSig，但仅适合快速调通 SDK 的基本功能，不适合线上产品，
 *            这是因为客户端代码中的 SECRETKEY 很容易被反编译逆向破解，尤其是 Web 端的代码被破解的难度几乎为零。
 *            一旦您的密钥泄露，攻击者就可以计算出正确的 UserSig 来盗用您的腾讯云流量。
 *
 *            正确的做法是将 UserSig 的计算代码和加密密钥放在您的业务服务器上，然后由 App 按需向您的服务器获取实时算出的 UserSig。
 *            由于破解服务器的成本要高于破解客户端 App，所以服务器计算的方案能够更好地保护您的加密密钥。
 *
 * Reference：https://cloud.tencent.com/document/product/269/32688#Server
 */

import Foundation
import CommonCrypto
import zlib

/**
 * 腾讯云直播license管理页面(https://console.cloud.tencent.com/live/license)
 * 当前应用的License LicenseUrl
 *
 * License Management View (https://console.cloud.tencent.com/live/license)
 * License URL of your application
 */
let LICENSEURL = ""

/**
 * 腾讯云直播license管理页面(https://console.cloud.tencent.com/live/license)
 * 当前应用的License Key
 *
 * License Management View (https://console.cloud.tencent.com/live/license)
 * License key of your application
 */
let LICENSEURLKEY = ""

/**
 * 腾讯云 SDKAppId，需要替换为您自己账号下的 SDKAppId。
 *
 * 进入腾讯云云通信[控制台](https://console.cloud.tencent.com/avc) 创建应用，即可看到 SDKAppId，
 * 它是腾讯云用于区分客户的唯一标识。
 */
let SDKAPPID: Int = 0

/**
 *  签名过期时间，建议不要设置的过短
 *
 *  时间单位：秒
 *  默认时间：7 x 24 x 60 x 60 = 604800 = 7 天
 */
let EXPIRETIME: Int = 0

/**
 * CDN发布功能 混流appId
 */
let CDNAPPID = 0

/**
 * CDN发布功能 混流bizId
 */
let CDNBIZID = 0

/**
 * CDN发布功能 混流CDN_URL
 */
let kCDN_URL: String = ""

/**
 * 计算签名用的加密密钥，获取步骤如下：
 *
 * step1. 进入腾讯云云通信[控制台](https://console.cloud.tencent.com/avc) ，如果还没有应用就创建一个，
 * step2. 单击“应用配置”进入基础配置页面，并进一步找到“帐号体系集成”部分。
 * step3. 点击“查看密钥”按钮，就可以看到计算 UserSig 使用的加密的密钥了，请将其拷贝并复制到如下的变量中
 *
 * 注意：该方案仅适用于调试Demo，正式上线前请将 UserSig 计算代码和密钥迁移到您的后台服务器上，以避免加密密钥泄露导致的流量盗用。
 * 文档：https://cloud.tencent.com/document/product/269/32688#Server
 */
let SECRETKEY = ""

/**
 * 计算 UserSig 签名
 *
 * 函数内部使用 HMAC-SHA256 非对称加密算法，对 SDKAPPID、userId 和 EXPIRETIME 进行加密。
 *
 * @note: 请不要将如下代码发布到您的线上正式版本的 App 中，原因如下：
 *
 * 本文件中的代码虽然能够正确计算出 UserSig，但仅适合快速调通 SDK 的基本功能，不适合线上产品，
 * 这是因为客户端代码中的 SECRETKEY 很容易被反编译逆向破解，尤其是 Web 端的代码被破解的难度几乎为零。
 * 一旦您的密钥泄露，攻击者就可以计算出正确的 UserSig 来盗用您的腾讯云流量。
 *
 * 正确的做法是将 UserSig 的计算代码和加密密钥放在您的业务服务器上，然后由 App 按需向您的服务器获取实时算出的 UserSig。
 * 由于破解服务器的成本要高于破解客户端 App，所以服务器计算的方案能够更好地保护您的加密密钥。
 *
 * 文档：https://cloud.tencent.com/document/product/269/32688#Server
 */

let PUSHURL = ""

/**
 * 配置的拉流地址
 *
 * 腾讯云域名管理页面：https://console.cloud.tencent.com/live/domainmanage
 */
let PLAY_DOMAIN: String = ""

/**
 * 配置的后台服务域名，类似：https://service-3vscss6c-xxxxxxxxxxx.gz.apigw.tencentcs.com"
 *
 * 小直播后台提供有登录、房间列表等服务，更多细节见文档：https://cloud.tencent.com/document/product/454/38625
 */
let SERVERLESSURL = ""

///
let SDKAppID = 0

class GenerateTestUserSig {
    
    class func genTestUserSig(identifier: String) -> String {
        let current = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970
        let TLSTime: CLong = CLong(floor(current))
        var obj: [String: Any] = [
            "TLS.ver": "2.0",
            "TLS.identifier": identifier,
            "TLS.sdkappid":SDKAppID,
            "TLS.expire": EXPIRETIME,
            "TLS.time": TLSTime
        ]
        let keyOrder = [
            "TLS.identifier",
            "TLS.sdkappid",
            "TLS.time",
            "TLS.expire"
        ]
        var stringToSign = ""
        keyOrder.forEach { (key) in
            if let value = obj[key] {
                stringToSign += "\(key):\(value)\n"
            }
        }
        print("string to sign: \(stringToSign)")
        if let sig = hmac(stringToSign) {
            obj["TLS.sig"] = sig
            print("sig: \(String(describing: sig))")
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: obj, options: .sortedKeys) else { return "" }
        
        let bytes = jsonData.withUnsafeBytes { (result) -> UnsafePointer<Bytef> in
            if let baseAddress = result.bindMemory(to: Bytef.self).baseAddress {
                return baseAddress
            }
            return UnsafePointer<Bytef>.init("")
        }
        let srcLen: uLongf = uLongf(jsonData.count)
        let upperBound: uLong = compressBound(srcLen)
        let capacity: Int = Int(upperBound)
        let dest: UnsafeMutablePointer<Bytef> = UnsafeMutablePointer<Bytef>.allocate(capacity: capacity)
        var destLen = upperBound
        let ret = compress2(dest, &destLen, bytes, srcLen, Z_BEST_SPEED)
        if ret != Z_OK {
            print("[Error] Compress Error \(ret), upper bound: \(upperBound)")
            dest.deallocate()
            return ""
        }
        let count = Int(destLen)
        let result = self.base64URL(data: Data.init(bytesNoCopy: dest, count: count, deallocator: .free))
        return result
    }
    
    class func hmac(_ plainText: String) -> String? {
        let cData = plainText.cString(using: String.Encoding.ascii)
        
        let cKeyLen = SECRETKEY.lengthOfBytes(using: .ascii)
        let cDataLen = plainText.lengthOfBytes(using: .ascii)
        
        var cHMAC = [CUnsignedChar].init(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        let pointer = cHMAC.withUnsafeMutableBufferPointer { (unsafeBufferPointer) in
            return unsafeBufferPointer
        }
        guard let cKey = SECRETKEY.cString(using: String.Encoding.ascii) else { return "" }
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), cKey, cKeyLen, cData, cDataLen, pointer.baseAddress)
        guard let baseAddress = pointer.baseAddress else { return "" }
        let data = Data.init(bytes: baseAddress, count: cHMAC.count)
        return data.base64EncodedString(options: [])
    }
    
    class func base64URL(data: Data) -> String {
        let result = data.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
        var final = ""
        result.forEach { (char) in
            switch char {
            case "+":
                final += "*"
            case "/":
                final += "-"
            case "=":
                final += "_"
            default:
                final += "\(char)"
            }
        }
        return final
    }
    
    class func generatePushPullStreamAddress(handler: @escaping ((String, String)?) -> Void) {
        guard let url = URL.init(string: PUSHURL) else {
            debugPrint("Invalid url address")
            return
        }
        var urlRequest = URLRequest.init(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                debugPrint("internalSendRequest failed，NSURLSessionDataTask return error des:\(error.localizedDescription)")
                DispatchQueue.main.async {
                    handler(nil)
                }
                return
            }
            guard let data = data else {
                debugPrint("response data is nil")
                DispatchQueue.main.async {
                    handler(nil)
                }
                return
            }
            guard let jsonStr = String.init(data: data, encoding: .utf8) else {
                debugPrint("data convert utf8 string error")
                DispatchQueue.main.async {
                    handler(nil)
                }
                return
            }
            guard let jsonData = jsonStr.data(using: .utf8) else {
                debugPrint("string convert utf8 data error")
                DispatchQueue.main.async {
                    handler(nil)
                }
                return
            }
            if let jsonDic = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String : String] {
                guard let pushURL = jsonDic["url_push"], let playURL = jsonDic["url_play_flv"] else {
                    debugPrint("url is nil")
                    DispatchQueue.main.async {
                        handler(nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    debugPrint("_____push URL = \(pushURL), play URL = \(playURL)")
                    handler((pushURL,playURL))
                }
            } else {
                DispatchQueue.main.async {
                    handler(nil)
                }
            }
        }
        task.resume()
    }
}
