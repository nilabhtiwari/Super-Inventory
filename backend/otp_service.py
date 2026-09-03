"""
Super Inventory Real OTP Dispatch Service (Python smtplib + WhatsApp)
100% Free Forever & Secure
- Gmail SMTP: TLS Port 587 with Google App Password
- WhatsApp Gateway: Direct API & Free Deep-Link Dispatch
- Local HTTP REST Server with CORS support for localhost:8080
"""

import os
import sys
import json
import smtplib
from http.server import HTTPServer, BaseHTTPRequestHandler
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import urllib.parse

# Configuration Path
CONFIG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "email_config.json")

def load_email_config():
    default_config = {
        "gmail_sender": "your_email@gmail.com",
        "gmail_app_password": "your_16_char_app_password",
        "sender_name": "Super Inventory Terminal"
    }
    if not os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "w", encoding="utf-8") as f:
            json.dump(default_config, f, indent=2)
        return default_config
    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default_config

def send_real_gmail_otp(recipient_email, otp_code):
    config = load_email_config()
    sender_email = config.get("gmail_sender", "")
    app_password = config.get("gmail_app_password", "").replace(" ", "")
    sender_name = config.get("sender_name", "Super Inventory Terminal")

    if not sender_email or "your_email" in sender_email or not app_password or "your_16_char" in app_password:
        return {
            "success": False,
            "error": "Gmail configuration not set. Please add your Gmail and 16-character App Password to backend/email_config.json"
        }

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"Super Inventory - Your Verification Code is {otp_code}"
        msg["From"] = f"{sender_name} <{sender_email}>"
        msg["To"] = recipient_email

        html_body = f"""
        <!DOCTYPE html>
        <html>
        <body style="margin: 0; padding: 20px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0f172a; color: #ffffff;">
          <div style="max-width: 460px; margin: auto; background-color: #1e293b; border: 1px solid rgba(255,255,255,0.1); border-radius: 24px; padding: 32px; text-align: center; box-shadow: 0 20px 40px rgba(0,0,0,0.5);">
            <div style="display: inline-block; background: linear-gradient(135deg, #a855f7, #ec4899); border-radius: 20px; padding: 12px; margin-bottom: 16px;">
              <span style="font-size: 28px; color: #ffffff; font-weight: bold;">SI</span>
            </div>
            <h1 style="font-size: 22px; font-weight: 800; margin: 0 0 8px; color: #ffffff;">Super Inventory</h1>
            <p style="font-size: 13px; color: #94a3b8; margin: 0 0 24px;">For All Inventory Ecosystem</p>
            
            <p style="font-size: 14px; color: #cbd5e1; margin-bottom: 16px; line-height: 1.5;">
              Use the following 6-digit security code to sign in to your store terminal:
            </p>

            <div style="background: rgba(0, 0, 0, 0.4); border: 1px solid rgba(255, 255, 255, 0.15); border-radius: 16px; padding: 18px; margin-bottom: 24px;">
              <span style="font-family: monospace; font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #f43f5e;">{otp_code}</span>
            </div>

            <p style="font-size: 12px; color: #64748b; margin: 0; line-height: 1.4;">
              ⏱ This code is valid for <strong>5 minutes</strong>.<br>
              🔒 Never share this verification code with anyone.
            </p>
          </div>
        </body>
        </html>
        """

        msg.attach(MIMEText(html_body, "html"))

        # Connect with TLS encryption
        with smtplib.SMTP("smtp.gmail.com", 587, timeout=10) as server:
            server.starttls()
            server.login(sender_email, app_password)
            server.sendmail(sender_email, recipient_email, msg.as_string())

        return {
            "success": True,
            "message": f"Real OTP successfully sent to {recipient_email}"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

class OTPRequestHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        if self.path == "/api/status":
            config = load_email_config()
            configured = "your_email" not in config.get("gmail_sender", "")
            self.send_response(200)
            self._send_cors_headers()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "service": "Super Inventory Real OTP Gateway",
                "status": "online",
                "gmail_configured": configured,
                "whatsapp_gateway": "ready (free forever)"
            }).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")
        
        try:
            data = json.loads(body) if body else {}
        except Exception:
            data = {}

        if self.path == "/api/send-email-otp":
            email = data.get("email", "").strip()
            otp = data.get("otp", "").strip()

            if not email or not otp:
                res = {"success": False, "error": "Email and OTP code are required"}
            else:
                res = send_real_gmail_otp(email, otp)

            self.send_response(200 if res.get("success") else 400)
            self._send_cors_headers()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(res).encode("utf-8"))

        elif self.path == "/api/send-whatsapp-otp":
            phone = data.get("phone", "").replace("+", "").replace(" ", "").replace("-", "")
            otp = data.get("otp", "").strip()
            if len(phone) == 10:
                phone = "91" + phone
            msg = f"Super Inventory Verification Code: {otp}. Valid for 5 minutes. Never share this code."
            deep_link = f"https://api.whatsapp.com/send?phone={phone}&text={urllib.parse.quote(msg)}"
            
            res = {
                "success": True,
                "whatsapp_link": deep_link,
                "message": f"WhatsApp dispatch link created for {phone}"
            }
            self.send_response(200)
            self._send_cors_headers()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(res).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

def run_server(port=5050):
    server_address = ("127.0.0.1", port)
    httpd = HTTPServer(server_address, OTPRequestHandler)
    print(f"============================================================")
    print(f">> Super Inventory OTP Gateway running on http://127.0.0.1:{port}")
    print(f">> Gmail SMTP: Configured in backend/email_config.json")
    print(f">> WhatsApp Gateway: Active (Free Forever)")
    print(f"============================================================")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping OTP service...")
        httpd.server_close()

if __name__ == "__main__":
    if "--test-email" in sys.argv:
        idx = sys.argv.index("--test-email")
        test_to = sys.argv[idx + 1] if idx + 1 < len(sys.argv) else "recipient@gmail.com"
        test_code = "782914"
        print(f"Sending test OTP {test_code} to {test_to}...")
        result = send_real_gmail_otp(test_to, test_code)
        print("Result:", result)
    else:
        run_server(5050)
