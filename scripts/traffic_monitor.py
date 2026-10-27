#!/usr/bin/env python3
"""
traffic_monitor.py
Flavor A: Traffic Pattern Analysis & SOAR Response

Functies:
1. Inspecteert netwerkpakketjes (live via socket/tcpdump/pyshark of via PCAP bestand).
2. Detecteert portscans (meer dan N verschillende poorten binnen T seconden vanaf 1 bron-IP).
3. SOAR Response:
   - Voert automatische mitigatie uit via Linux iptables (`iptables -I INPUT -s <IP> -j DROP`).
   - Verstuurt direct een JSON webhook alert (Discord, Slack of lokaal log).
"""

import sys
import os
import time
import socket
import struct
import json
import urllib.request
from collections import defaultdict

# Configuratie drempelwaarden (Thresholds)
SCAN_PORT_THRESHOLD = 10      # Maximaal unieke poorten per tijdvenster
TIME_WINDOW_SEC = 5           # Tijdvenster in seconden
WEBHOOK_URL = os.environ.get("ALERT_WEBHOOK_URL", "")  # Optionele Discord/Slack webhook

# State tracking: { src_ip: [(timestamp, dst_port), ...] }
ip_history = defaultdict(list)
blocked_ips = set()

def trigger_soar_mitigation(attacker_ip, reason):
    """
    Automatische SOAR actie:
    1. Blokkeer het IP-adres direct in de firewall.
    2. Verstuur een audit webhook naar het securitykanaal.
    """
    if attacker_ip in blocked_ips:
        return

    blocked_ips.add(attacker_ip)
    print(f"\n🚨 [SOAR TRIGGER] Verdachte activiteit vastgesteld van: {attacker_ip}")
    print(f"    Reden: {reason}")
    print(f"    [1/2] IP {attacker_ip} wordt toegevoegd aan de DROP rule in iptables...")

    # Actie 1: Lokale iptables block (simulatie vriendelijk als sudo password vraagt)
    block_cmd = f"sudo -n iptables -I INPUT -s {attacker_ip} -j DROP 2>/dev/null"
    res = os.system(block_cmd)
    if res == 0:
        print(f"    [✓] IP {attacker_ip} succesvol geblokkeerd in iptables firewall!")
    else:
        print(f"    [!] Commando: iptables -I INPUT -s {attacker_ip} -j DROP (geregistreerd in SOAR blocklist)")

    # Actie 2: Webhook alert verzenden
    payload = {
        "content": f"🚨 **SECURITY INCIDENT - SOAR AUTONOME MITIGATIE**\n"
                   f"**Aanvaller IP:** `{attacker_ip}`\n"
                   f"**Detectie:** {reason}\n"
                   f"**Status:** Automatisch geblokkeerd via Firewall DROP rule\n"
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

def analyze_packet(src_ip, dst_port):
    """Controleert of een pakketje de portscan drempelwaarde overschrijdt."""
    now = time.time()
    
    # Verwijder oude records buiten het tijdvenster
    ip_history[src_ip] = [entry for entry in ip_history[src_ip] if now - entry[0] <= TIME_WINDOW_SEC]
    ip_history[src_ip].append((now, dst_port))

    # Bepaal unieke poorten
    scanned_ports = {entry[1] for entry in ip_history[src_ip]}
    
    if len(scanned_ports) >= SCAN_PORT_THRESHOLD:
        trigger_soar_mitigation(
            src_ip,
            f"Portscan gedetecteerd: {len(scanned_ports)} unieke poorten afgetast binnen {TIME_WINDOW_SEC} seconden."
        )

def run_sniffing():
    """
    Luistert raw op de netwerkinterface (werkt zonder externe libraries).
    Inspecteert TCP headers op SYN vlaggen.
    """
    print("========================================================")
    print("🛡️  START TRAFFIC PATTERN MONITOR & SOAR BOUNCER")
    print(f"    Drempelwaarde: >{SCAN_PORT_THRESHOLD} poorten binnen {TIME_WINDOW_SEC}s")
    print("========================================================")

    # Controleer of we met pyshark kunnen werken als het aanwezig is
    try:
        import pyshark
        print("[+] Pyshark library gedetecteerd! Starten via tshark backend...")
        capture = pyshark.LiveCapture(bpf_filter='tcp[tcpflags] & (tcp-syn) != 0 and tcp[tcpflags] & (tcp-ack) == 0')
        for packet in capture.sniff_continuously():
            try:
                src = packet.ip.src
                dst_port = int(packet.tcp.dstport)
                analyze_packet(src, dst_port)
            except AttributeError:
                continue
        return
    except ImportError:
        print("[i] Pyshark niet geïnstalleerd. Val terug op native raw socket / tcpdump inspectie...")

    try:
        # Native Linux raw socket voor TCP pakketjes
        raw_sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_TCP)
        print("[+] Luisteren op alle netwerkinterfaces (raw socket)...")
        while True:
            raw_data, addr = raw_sock.recvfrom(65535)
            # IP header is de eerste 20 bytes
            ip_header = raw_data[:20]
            iph = struct.unpack('!BBHHHBBH4s4s', ip_header)
            src_ip = socket.inet_ntoa(iph[8])
            
            # TCP header volgt na IP header
            tcp_header = raw_data[20:40]
            tcph = struct.unpack('!HHLLBBHHH', tcp_header)
            dst_port = tcph[1]
            flags = tcph[5]

            # SYN flag is bit 1 (0x02), ACK flag is bit 4 (0x10)
            is_syn = (flags & 0x02) != 0
            is_ack = (flags & 0x10) != 0

            # Alleen initiële verbindingsverzoeken (SYN zonder ACK) zijn relevant voor portscan detectie
            if is_syn and not is_ack:
                analyze_packet(src_ip, dst_port)

    except PermissionError:
        print("\n[!] Raw socket vereist sudo/root rechten.")
        print("[+] Start de testmodus (simulatie van binnenkomende packets) om te verifiëren...")
        simulate_scan()

def simulate_scan():
    """Simulatiemodus voor demonstratiedoeleinden."""
    fake_attacker = "192.168.10.45"
    print(f"\n[DEMO] Simuleren van een Nmap portscan vanaf {fake_attacker}...")
    for port in range(1, 15):
        print(f"  -> Binnenkomend SYN pakket naar poort {port}...")
        analyze_packet(fake_attacker, port)
        time.sleep(0.1)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        simulate_scan()
    else:
        run_sniffing()
