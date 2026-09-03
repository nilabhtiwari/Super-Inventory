"""
WhatsApp Business Cloud API - Automated Invoice Sender
Official Meta Graph API v19.0 Integration for Super Inventory POS

Usage:
  python whatsapp_invoice_sender.py --phone 919876543210 --invoice INV-20260904-4821
"""

import os
import sys
import json
import urllib.request
import urllib.error

# Meta WhatsApp Cloud API Configurations
# Store owners can obtain these from https://developers.facebook.com
WHATSAPP_TOKEN = os.environ.get("WHATSAPP_ACCESS_TOKEN", "YOUR_META_PERMANENT_ACCESS_TOKEN")
PHONE_NUMBER_ID = os.environ.get("WHATSAPP_PHONE_NUMBER_ID", "YOUR_WHATSAPP_PHONE_NUMBER_ID")

def send_whatsapp_invoice(recipient_phone: str, invoice_data: dict) -> dict:
    """
    Sends an automated official WhatsApp Tax Invoice message directly to the customer's phone.
    """
    # Clean phone number (ensure country code e.g. 91 for India)
    cleaned_phone = "".join(filter(str.isdigit, recipient_phone))
    if len(cleaned_phone) == 10:
        cleaned_phone = "91" + cleaned_phone

    api_url = f"https://graph.facebook.com/v19.0/{PHONE_NUMBER_ID}/messages"

    # Build formatted tax invoice text
    items_text = "\n".join([
        f"{idx + 1}. *{item['name']}*\n   Qty: {item['qty']} {item.get('unit', 'pcs')} @ ₹{item['rate']} | GST: {item.get('gst', 0)}%\n   Amt: ₹{item['total']}"
        for idx, item in enumerate(invoice_data.get("items", []))
    ])

    invoice_message = (
        f"🧾 *TAX INVOICE - {invoice_data.get('shop_name', 'SUPER INVENTORY STORE')}*\n"
        f"📍 {invoice_data.get('shop_address', 'Main Branch, City Centre')}\n"
        f"📋 GSTIN: {invoice_data.get('gstin', '27AAAAA0000A1Z5')}\n"
        f"----------------------------------------\n"
        f"*Invoice No:* {invoice_data.get('invoice_no')}\n"
        f"*Date:* {invoice_data.get('date')}\n"
        f"*Payment Mode:* {invoice_data.get('payment_mode', 'PAID VIA UPI QR')}\n"
        f"----------------------------------------\n"
        f"*ITEMS PURCHASED:*\n"
        f"{items_text}\n"
        f"----------------------------------------\n"
        f"*Subtotal (Taxable):* ₹{invoice_data.get('subtotal', 0):.2f}\n"
        f"*Total GST Tax:* ₹{invoice_data.get('gst_tax', 0):.2f}\n"
        f"💰 *FINAL AMOUNT:* *₹{invoice_data.get('grand_total', 0):.2f}*\n"
        f"----------------------------------------\n"
        f"📞 *Customer Support / Contact:* {invoice_data.get('phone', '9876543210')}\n"
        f"🎉 Thank you for shopping with us! Visit again."
    )

    payload = {
        "messaging_product": "whatsapp",
        "recipient_type": "individual",
        "to": cleaned_phone,
        "type": "text",
        "text": {
            "preview_url": False,
            "body": invoice_message
        }
    }

    req = urllib.request.Request(
        api_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {WHATSAPP_TOKEN}",
            "Content-Type": "application/json"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode("utf-8"))
            print(f"✓ WhatsApp Invoice successfully delivered to +{cleaned_phone}!")
            return {"success": True, "data": res_data}
    except urllib.error.HTTPError as e:
        error_msg = e.read().decode("utf-8")
        print(f"HTTP Error {e.code}: {error_msg}")
        return {"success": False, "error": error_msg}
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    sample_invoice = {
        "shop_name": "Super Inventory Store",
        "shop_address": "Main Branch • City Centre Road",
        "gstin": "27AAAAA0000A1Z5",
        "invoice_no": "INV-20260904-0015",
        "date": "04 Sep 2026",
        "payment_mode": "UPI QR (PAID)",
        "subtotal": 49.00,
        "gst_tax": 1.50,
        "grand_total": 50.50,
        "phone": "9876543210",
        "items": [
            {"name": "Britannia Marie Gold Biscuits (100g)", "qty": 2, "unit": "pcs", "rate": 15.0, "gst": 5.0, "total": 31.50},
            {"name": "Fresh Premium Basmati Rice (200g)", "qty": 1, "unit": "pcs", "rate": 19.0, "gst": 0.0, "total": 19.00}
        ]
    }
    
    target_phone = sys.argv[1] if len(sys.argv) > 1 else "919876543210"
    print(f"Dispatching real WhatsApp invoice to {target_phone}...")
    # Note: Requires valid WHATSAPP_ACCESS_TOKEN and PHONE_NUMBER_ID from Meta
    # In live preview, use the direct wa.me link button to send via WhatsApp app/web
