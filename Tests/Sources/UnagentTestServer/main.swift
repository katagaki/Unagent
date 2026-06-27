import Foundation
import Network

struct HTTPRequest {
    let method: String
    let path: String
    let headers: [(name: String, value: String)]

    func header(_ name: String) -> String? {
        let wanted = name.lowercased()
        return headers.first { $0.name.lowercased() == wanted }?.value
    }
}

func parseRequest(_ data: Data) -> HTTPRequest? {
    guard let text = String(data: data, encoding: .utf8) else { return nil }
    let lines = text.components(separatedBy: "\r\n")
    guard let requestLine = lines.first else { return nil }
    let parts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
    guard parts.count >= 2 else { return nil }

    var headers: [(name: String, value: String)] = []
    for line in lines.dropFirst() {
        if line.isEmpty { break }
        guard let colon = line.firstIndex(of: ":") else { continue }
        let name = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
        let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        headers.append((name, value))
    }
    return HTTPRequest(method: parts[0], path: parts[1], headers: headers)
}

func jsonString(_ string: String) -> String {
    var out = "\""
    for scalar in string.unicodeScalars {
        switch scalar {
        case "\"": out += "\\\""
        case "\\": out += "\\\\"
        case "\n": out += "\\n"
        case "\r": out += "\\r"
        case "\t": out += "\\t"
        default:
            if scalar.value < 0x20 {
                out += String(format: "\\u%04x", scalar.value)
            } else {
                out.unicodeScalars.append(scalar)
            }
        }
    }
    out += "\""
    return out
}

func httpResponse(status: String, contentType: String, body: Data) -> Data {
    var head = "HTTP/1.1 \(status)\r\n"
    head += "Content-Type: \(contentType)\r\n"
    head += "Content-Length: \(body.count)\r\n"
    head += "Cache-Control: no-store, no-cache, must-revalidate\r\n"
    head += "Access-Control-Allow-Origin: *\r\n"
    head += "Connection: close\r\n"
    head += "\r\n"
    var data = Data(head.utf8)
    data.append(body)
    return data
}

func pageHTML(serverUserAgent: String) -> String {
    let template = """
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Unagent Tester</title>
    <style>
      :root {
        color-scheme: light dark;
        --bg: #ffffff;
        --layer: #f4f4f4;
        --border-subtle: #e0e0e0;
        --text-primary: #161616;
        --text-secondary: #525252;
        --text-helper: #6f6f6f;
        --link: #0f62fe;
        --link-hover: #0353e9;
        --support-success: #198038;
        --support-error: #da1e28;
        --notification-success-bg: #defbe6;
        --notification-error-bg: #fff1f1;
      }
      @media (prefers-color-scheme: dark) {
        :root {
          --bg: #161616;
          --layer: #262626;
          --border-subtle: #393939;
          --text-primary: #f4f4f4;
          --text-secondary: #c6c6c6;
          --text-helper: #8d8d8d;
          --link: #78a9ff;
          --link-hover: #4589ff;
          --support-success: #42be65;
          --support-error: #fa4d56;
          --notification-success-bg: #1c2b1c;
          --notification-error-bg: #2d1a1a;
        }
      }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        background: var(--bg);
        color: var(--text-primary);
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, Roboto, "Helvetica Neue", Arial, sans-serif;
        font-size: 0.875rem;
        line-height: 1.25rem;
        -webkit-font-smoothing: antialiased;
      }
      .header {
        display: flex;
        align-items: center;
        height: 3rem;
        padding: 0 1rem;
        background: #161616;
        color: #ffffff;
      }
      .header__name { font-weight: 600; }
      .header__sep { width: 1px; height: 1.25rem; margin: 0 1rem; background: #525252; }
      .header__sub { color: #c6c6c6; }
      .content { max-width: 40rem; padding: 2rem 1rem; }
      h1 { font-size: 1.25rem; line-height: 1.625rem; font-weight: 400; margin: 0 0 1.5rem; }
      .notification {
        display: flex;
        align-items: flex-start;
        gap: 0.75rem;
        padding: 1rem;
        margin-bottom: 1.5rem;
        background: var(--layer);
        border-left: 3px solid var(--text-helper);
      }
      .notification__icon { flex: none; line-height: 0; }
      .notification__icon svg { width: 20px; height: 20px; fill: currentColor; }
      .notification__text { margin: 0; font-weight: 600; }
      .notification--success { background: var(--notification-success-bg); border-left-color: var(--support-success); }
      .notification--success .notification__icon { color: var(--support-success); }
      .notification--error { background: var(--notification-error-bg); border-left-color: var(--support-error); }
      .notification--error .notification__icon { color: var(--support-error); }
      .tile { padding: 1rem; margin-bottom: 1rem; background: var(--layer); border: 1px solid var(--border-subtle); }
      .tile__label {
        margin: 0 0 0.5rem;
        font-size: 0.75rem;
        line-height: 1rem;
        font-weight: 400;
        letter-spacing: 0.02em;
        color: var(--text-secondary);
      }
      code, .mono {
        font-family: ui-monospace, SFMono-Regular, Menlo, "Liberation Mono", monospace;
        font-size: 0.875rem;
        line-height: 1.25rem;
        word-break: break-all;
        color: var(--text-primary);
      }
      .big { font-size: 1.75rem; line-height: 2.25rem; font-weight: 400; word-break: normal; }
      .helper { color: var(--text-helper); }
      .btn {
        font-family: inherit;
        font-size: 0.875rem;
        line-height: 1.25rem;
        color: #ffffff;
        background: var(--link);
        border: none;
        border-radius: 0;
        padding: 0.875rem 4rem 0.875rem 1rem;
        min-height: 3rem;
        cursor: pointer;
      }
      .btn:hover { background: var(--link-hover); }
      .btn:focus { outline: 2px solid var(--bg); outline-offset: -4px; box-shadow: 0 0 0 2px var(--link); }
    </style>
    </head>
    <body>
      <div class="header">
        <span class="header__name">Unagent</span>
        <span class="header__sep"></span>
        <span class="header__sub">Tester</span>
      </div>

      <div class="content">

        <div id="verdict" class="notification">
          <span class="notification__icon" id="verdictIcon"></span>
          <p class="notification__text" id="verdictText">Checking…</p>
        </div>

        <div class="tile">
          <p class="tile__label">1 — User-Agent header (seen by the server)</p>
          <code id="serverUA"></code>
        </div>

        <div class="tile">
          <p class="tile__label">2 — navigator.userAgent (seen by JavaScript)</p>
          <code id="jsUA"></code>
        </div>

        <div class="tile">
          <p class="tile__label">3 — Viewport size</p>
          <div class="big mono" id="viewport"></div>
          <div class="mono helper" id="viewportDetail" style="margin-top:0.375rem;"></div>
        </div>

        <button class="btn" onclick="location.reload()">Refresh</button>
      </div>

      <script>
        const SERVER_UA = __SERVER_UA_JSON__;
        const set = (id, value) => { document.getElementById(id).textContent = value; };

        const ICON_SUCCESS = '<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M16,2A14,14,0,1,0,30,16,14,14,0,0,0,16,2ZM14,21.5,9,16.5l1.41-1.41L14,18.67l7.59-7.59L23,12.5Z"/></svg>';
        const ICON_ERROR = '<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M16,2A14,14,0,1,0,30,16,14,14,0,0,0,16,2Zm5,18.59L19.59,22,16,18.41,12.41,22,11,20.59,14.59,17,11,13.41,12.41,12,16,15.59,19.59,12,21,13.41,17.41,17Z"/></svg>';

        set('serverUA', SERVER_UA);
        set('jsUA', navigator.userAgent);

        const match = SERVER_UA === navigator.userAgent;
        document.getElementById('verdict').classList.add(match ? 'notification--success' : 'notification--error');
        document.getElementById('verdictIcon').innerHTML = match ? ICON_SUCCESS : ICON_ERROR;
        set('verdictText', match
          ? 'Header and navigator.userAgent match'
          : 'Mismatch — header and navigator.userAgent differ');

        function updateViewport() {
          set('viewport', window.innerWidth + ' × ' + window.innerHeight + ' px');
          const vv = window.visualViewport;
          set('viewportDetail',
            'devicePixelRatio ' + window.devicePixelRatio +
            (vv ? '  ·  visual ' + Math.round(vv.width) + ' × ' + Math.round(vv.height) + ' px' : ''));
        }
        updateViewport();
        window.addEventListener('resize', updateViewport);
        if (window.visualViewport) window.visualViewport.addEventListener('resize', updateViewport);
      </script>
    </body>
    </html>
    """
    return template.replacingOccurrences(of: "__SERVER_UA_JSON__", with: jsonString(serverUserAgent))
}

func makeResponse(for request: HTTPRequest) -> Data {
    let userAgent = request.header("User-Agent") ?? ""
    let path = request.path.split(separator: "?").first.map(String.init) ?? request.path

    switch path {
    case "/echo":
        var pairs = request.headers.map { "\(jsonString($0.name)): \(jsonString($0.value))" }
        pairs.sort()
        let json = "{\"userAgentHeader\": \(jsonString(userAgent)), \"headers\": {\(pairs.joined(separator: ", "))}}"
        return httpResponse(status: "200 OK", contentType: "application/json; charset=utf-8", body: Data(json.utf8))
    case "/favicon.ico":
        return httpResponse(status: "204 No Content", contentType: "text/plain", body: Data())
    default:
        let html = pageHTML(serverUserAgent: userAgent)
        return httpResponse(status: "200 OK", contentType: "text/html; charset=utf-8", body: Data(html.utf8))
    }
}

func receive(on connection: NWConnection, buffer: Data) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
        var accumulated = buffer
        if let data = data { accumulated.append(data) }

        if let terminator = accumulated.range(of: Data("\r\n\r\n".utf8)) {
            let headerData = accumulated.subdata(in: accumulated.startIndex..<terminator.upperBound)
            let response: Data
            if let request = parseRequest(headerData) {
                response = makeResponse(for: request)
            } else {
                response = httpResponse(status: "400 Bad Request", contentType: "text/plain", body: Data("Bad Request".utf8))
            }
            connection.send(content: response, completion: .contentProcessed { _ in
                connection.cancel()
            })
        } else if isComplete || error != nil {
            connection.cancel()
        } else {
            receive(on: connection, buffer: accumulated)
        }
    }
}

func handle(_ connection: NWConnection) {
    connection.start(queue: .global())
    receive(on: connection, buffer: Data())
}

func localIPv4Addresses() -> [String] {
    var addresses: [String] = []
    var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddrPointer) == 0, let first = ifaddrPointer else { return addresses }
    defer { freeifaddrs(ifaddrPointer) }

    var pointer: UnsafeMutablePointer<ifaddrs>? = first
    while let current = pointer {
        let interface = current.pointee
        if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
            let name = String(cString: interface.ifa_name)
            if name == "en0" || name == "en1" {
                var address = interface.ifa_addr.pointee
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(&address, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                addresses.append(String(cString: host))
            }
        }
        pointer = interface.ifa_next
    }
    return addresses
}

let portNumber: UInt16 = {
    if CommandLine.arguments.count > 1, let value = UInt16(CommandLine.arguments[1]) { return value }
    if let env = ProcessInfo.processInfo.environment["UNAGENT_PORT"], let value = UInt16(env) { return value }
    return 8624
}()

guard let port = NWEndpoint.Port(rawValue: portNumber) else {
    FileHandle.standardError.write(Data("Invalid port \(portNumber)\n".utf8))
    exit(1)
}

let parameters = NWParameters.tcp
parameters.allowLocalEndpointReuse = true

do {
    let listener = try NWListener(using: parameters, on: port)
    listener.newConnectionHandler = handle
    listener.stateUpdateHandler = { state in
        switch state {
        case .ready:
            print("Unagent test server listening on port \(portNumber)")
            print("  From the iOS Simulator:  http://localhost:\(portNumber)")
            for address in localIPv4Addresses() {
                print("  From a physical device:  http://\(address):\(portNumber)")
            }
            print("Open the URL in Safari, set a user-agent preset in Unagent, then reload.")
        case .failed(let error):
            FileHandle.standardError.write(Data("Listener failed: \(error)\n".utf8))
            exit(1)
        default:
            break
        }
    }
    listener.start(queue: .main)
    dispatchMain()
} catch {
    FileHandle.standardError.write(Data("Failed to start server: \(error)\n".utf8))
    exit(1)
}
