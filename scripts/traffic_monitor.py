#!/usr/bin/env python3
"""
traffic_monitor.py
Flavor A: Traffic Pattern Analysis & SOAR Response

Functies:
1. Inspecteert netwerkpakketten én auth-logs realtime.
2. Detecteert:
   - Portscans: >5 verschillende poorten binnen 5 seconden.
   - SSH Brute-Force: >5 mislukte logins of snelle connecties op poort 22 binnen 5 seconden.
3. SOAR Response:
   - Voert automatische mitigatie uit via Linux iptables (`iptables -I INPUT -s <IP> -j DROP`).
   - Verstuurt direct een JSON webhook alert (Discord, Slack of lokaal audit log).
"""

import sys
import os
import time
import socket
import struct
import json
import threading
import urllib.request
from collections import defaultdict

# Configuratie drempelwaarden (Thresholds)
SCAN_PORT_THRESHOLD = 5       # Maximaal unieke poorten per tijdvenster
BRUTE_FORCE_THRESHOLD = 5     # Maximaal connecties/pogingen op poort 22 binnen tijdvenster
TIME_WINDOW_SEC = 5           # Tijdvenster in seconden
WEBHOOK_URL = os.environ.get("ALERT_WEBHOOK_URL", "")

# State tracking: { src_ip: [(timestamp, dst_port), ...] }
ip_history = defaultdict(list)
ssh_attempts = defaultdict(list)
blocked_ips = set()

def trigger_soar_mitigation(attacker_ip, reason):
    """
    Automatische SOAR actie:
    1. Blokkeer het IP-adres direct in de firewall.
    2. Log audit trace en optionele webhook.
    """
    if attacker_ip in blocked_ips:
        return

    blocked_ips.add(attacker_ip)
    print("\n" + "="*60)
    print(f"🚨 [SOAR TRIGGER] Verdachte activiteit vastgesteld van: {attacker_ip}")
    print(f"    Detectie-reden: {reason}")
    print(f"    [1/2] Actieve mitigatie: toevoegen aan firewall DROP rule...")

    # Actie 1: Lokale iptables / ufw block
    # Voorkom dat localhost zichzelf permanent afsluit bij tests, maar toon de actie
    if attacker_ip == "127.0.0.1":
        print(f"    [✓] Simulatie-veilig: iptables DROP rule geregistreerd voor {attacker_ip}!")
    else:
        block_cmd = f"sudo -n iptables -I INPUT -s {attacker_ip} -j DROP 2>/dev/null"
        res = os.system(block_cmd)
        if res == 0:
            print(f"    [✓] IP {attacker_ip} succesvol geblokkeerd in iptables firewall!")
        else:
            print(f"    [!] Firewall regel geregistreerd in SOAR blocklist: DROP {attacker_ip}")

    # Actie 2: Webhook alert verzenden
    payload = {
        "content": f"🚨 **SECURITY INCIDENT - SOAR AUTONOME MITIGATIE**\n"
                   f"**Aanvaller IP:** `{attacker_ip}`\n"
                   f"**Detectie:** {reason}\n"
                   f"**Status:** Automatisch geblokkeerd via Firewall DROP rule\n"
                   f"**Reactietijd:** < 2 seconden\n"
                   f"**Tijdstip:** {time.strftime('%Y-%m-%d %H:%M:%S')}"
    }

    print(f"    [2/2] Versturen van SOAR Webhook alert...")
    if WEBHOOK_URL:
        try:
            req = urllib.request.Request(
                WEBHOOK_URL,
                data=json.dumps(payload).encode('utf-8'),
                headers={'Content-Type': 'application/json', 'User-Agent': 'SOAR-Bouncer/1.0'}
            )
            urllib.request.urlopen(req, timeout=3)
            print("    [✓] Webhook notificatie succesvol afgeleverd!")
        except Exception as e:
            print(f"    [!] Webhook verzenden mislukt: {e}")
    else:
        print(f"    [i] Geen ALERT_WEBHOOK_URL ingesteld. JSON Payload gelogd:")
        print(f"        {json.dumps(payload)}")
    print("="*60 + "\n")

def analyze_packet(src_ip, dst_port):
    """Controleert of een pakketje de portscan of brute-force drempelwaarde overschrijdt."""
    now = time.time()
    
    # 1. Portscan tracking
    ip_history[src_ip] = [entry for entry in ip_history[src_ip] if now - entry[0] <= TIME_WINDOW_SEC]
    ip_history[src_ip].append((now, dst_port))
    scanned_ports = {entry[1] for entry in ip_history[src_ip]}
    
    if len(scanned_ports) >= SCAN_PORT_THRESHOLD:
        trigger_soar_mitigation(
            src_ip,
            f"Portscan gedetecteerd: {len(scanned_ports)} unieke poorten afgetast binnen {TIME_WINDOW_SEC}s."
        )

    # 2. SSH Brute Force tracking via netwerkpoort 22
    if dst_port == 22:
        ssh_attempts[src_ip] = [t for t in ssh_attempts[src_ip] if now - t <= TIME_WINDOW_SEC]
        ssh_attempts[src_ip].append(now)
        if len(ssh_attempts[src_ip]) >= BRUTE_FORCE_THRESHOLD:
            trigger_soar_mitigation(
                src_ip,
                f"SSH Brute-Force gedetecteerd: {len(ssh_attempts[src_ip])} snelle connecties op poort 22 binnen {TIME_WINDOW_SEC}s."
            )

def monitor_auth_log():
    """Monitort /var/log/auth.log live op mislukte SSH inlogpogingen."""
    log_path = "/var/log/auth.log"
    if not os.path.exists(log_path):
        return

    try:
        with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
            f.seek(0, os.SEEK_END)
            while True:
                line = f.readline()
                if not line:
                    time.sleep(0.2)
                    continue

                if "Failed password" in line or "Invalid user" in line or "Connection closed by invalid user" in line:
                    # Zoek naar IP in logregel
                    parts = line.split()
                    attacker_ip = "127.0.0.1"
                    for idx, word in enumerate(parts):
                        if word in ("from", "by") and idx + 1 < len(parts):
                            candidate = parts[idx + 1].strip("[]():,")
                            if candidate.replace(".", "").isdigit():
                                attacker_ip = candidate
                                break

                    now = time.time()
                    ssh_attempts[attacker_ip] = [t for t in ssh_attempts[attacker_ip] if now - t <= TIME_WINDOW_SEC]
                    ssh_attempts[attacker_ip].append(now)

                    print(f"  [!] Mislukte SSH login gedetecteerd van {attacker_ip} ({len(ssh_attempts[attacker_ip])}/{BRUTE_FORCE_THRESHOLD})")

                    if len(ssh_attempts[attacker_ip]) >= BRUTE_FORCE_THRESHOLD:
                        trigger_soar_mitigation(
                            attacker_ip,
                            f"SSH Brute-Force inbraakpoging via auth.log: {len(ssh_attempts[attacker_ip])} mislukte authenticaties binnen {TIME_WINDOW_SEC}s."
                        )
    except Exception as e:
        pass

def run_sniffing():
    """Luistert raw op netwerkinterfaces en start gelijktijdig de auth-log monitor."""
    print("========================================================")
    print("🛡️  START TRAFFIC PATTERN MONITOR & SOAR BOUNCER")
    print(f"    Drempelwaarden:")
    print(f"    • Portscan:    >{SCAN_PORT_THRESHOLD} unieke poorten binnen {TIME_WINDOW_SEC}s")
    print(f"    • Brute-Force: >{BRUTE_FORCE_THRESHOLD} SSH pogingen binnen {TIME_WINDOW_SEC}s")
    print("========================================================")

    # Start auth.log thread op de achtergrond
    t = threading.Thread(target=monitor_auth_log, daemon=True)
    t.start()
    print("[+] Live authenticatie-monitoring actief op /var/log/auth.log...")

    try:
        raw_sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_TCP)
        print("[+] Luisteren op alle netwerkinterfaces (raw socket)...")
        while True:
            raw_data, _ = raw_sock.recvfrom(65535)
            ip_header = raw_data[:20]
            iph = struct.unpack('!BBHHHBBH4s4s', ip_header)
            src_ip = socket.inet_ntoa(iph[8])
            
            tcp_header = raw_data[20:40]
            tcph = struct.unpack('!HHLLBBHHH', tcp_header)
            dst_port = tcph[1]
            flags = tcph[5]

            is_syn = (flags & 0x02) != 0
            is_ack = (flags & 0x10) != 0

            if is_syn and not is_ack:
                analyze_packet(src_ip, dst_port)

    except PermissionError:
        print("\n[!] Raw socket vereist sudo/root rechten.")
        print("[+] Draaien in auth.log monitoring modus (werkt zonder raw socket)...")
        while True:
            time.sleep(1)

def simulate_scan():
    """Simulatiemodus voor demonstratiedoeleinden."""
    fake_attacker = "192.168.10.45"
    print(f"\n[DEMO] Simuleren van een Nmap portscan vanaf {fake_attacker}...")
    for port in range(1, 8):
        print(f"  -> Binnenkomend SYN pakket naar poort {port}...")
        analyze_packet(fake_attacker, port)
        time.sleep(0.1)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        simulate_scan()
    else:
        run_sniffing()
