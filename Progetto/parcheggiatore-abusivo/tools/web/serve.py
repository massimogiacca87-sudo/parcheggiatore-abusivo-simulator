import http.server, socketserver, os
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()
socketserver.TCPServer.allow_reuse_address = True
os.chdir("/tmp/mini/build")
with socketserver.TCPServer(("127.0.0.1", 8766), H) as h:
    h.serve_forever()
