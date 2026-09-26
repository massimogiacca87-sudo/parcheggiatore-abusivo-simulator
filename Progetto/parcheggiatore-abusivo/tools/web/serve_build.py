# Serve build/web con gli header che servono ai thread (come itch.io con
# «SharedArrayBuffer support»). Uso: python3 tools/web/serve_build.py [porta]
import http.server, socketserver, os, sys
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()
    def log_message(self, *a):
        pass
socketserver.TCPServer.allow_reuse_address = True
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "build", "web"))
porta = int(sys.argv[1]) if len(sys.argv) > 1 else 8767
with socketserver.TCPServer(("127.0.0.1", porta), H) as h:
    h.serve_forever()
