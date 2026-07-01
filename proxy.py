import os
import socket
import select
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
import http.client

ST_PORT = 8000
HUB_PORT = 7860

class ThreadPoolHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True
    request_queue_size = 512

class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format, *args):
        pass # Suppress logs for performance

    def _proxy_websocket(self):
        lines = [f"{self.command} {self.path} {self.request_version}"]
        for key, value in self.headers.items():
            if key.lower() == "host":
                value = f"127.0.0.1:{ST_PORT}"
            lines.append(f"{key}: {value}")
        lines.extend(["", ""])
        payload = "\r\n".join(lines).encode("latin-1", errors="replace")

        client = self.connection
        backend = socket.create_connection(("127.0.0.1", ST_PORT), timeout=60)
        try:
            backend.sendall(payload)
            sockets = [client, backend]
            while True:
                readable, _, _ = select.select(sockets, [], [], 3600)
                if not readable:
                    break
                for sock in readable:
                    chunk = sock.recv(65536)
                    if not chunk:
                        return
                    other = backend if sock is client else client
                    other.sendall(chunk)
        finally:
            backend.close()

    def _proxy_http(self, method):
        conn = http.client.HTTPConnection("127.0.0.1", ST_PORT, timeout=120)
        length = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(length) if length else None

        headers = {}
        for key, value in self.headers.items():
            if key.lower() == "host":
                value = f"127.0.0.1:{ST_PORT}"
            headers[key] = value
        
        try:
            conn.request(method, self.path, body=body, headers=headers)
            resp = conn.getresponse()
            data = resp.read()
            
            self.send_response(resp.status)
            for key, value in resp.getheaders():
                if key.lower() not in ("connection", "keep-alive", "transfer-encoding"):
                    self.send_header(key, value)
            self.end_headers()
            self.wfile.write(data)
        finally:
            conn.close()

    def handle(self):
        try:
            self.raw_requestline = self.rfile.readline(65537)
            if not self.raw_requestline:
                return
            if not self.parse_request():
                return
            if self.headers.get("Upgrade", "").lower() == "websocket":
                self._proxy_websocket()
            else:
                self._proxy_http(self.command)
        except Exception:
            pass

if __name__ == "__main__":
    print(f"Starting Python WebSocket Proxy on port {HUB_PORT}, forwarding to SillyTavern on {ST_PORT}...", flush=True)
    server = ThreadPoolHTTPServer(("0.0.0.0", HUB_PORT), Handler)
    server.serve_forever()
