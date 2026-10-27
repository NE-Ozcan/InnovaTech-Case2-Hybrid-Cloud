#!/usr/bin/env bash
# ==============================================================================
# Script: attack_cryptominer.sh
# Doel: Simuleert het gedrag van een kwaadwillende cryptominer (bijv. XMRig)
#       door plotseling alle CPU-kernen naar 100% te jagen en RAM te alloceren.
# Bewijs: Te zien in Prometheus / Grafana Node Exporter dashboards.
# ==============================================================================

DURATION_SEC=${1:-30}
echo "========================================================"
echo "[!] START CRYPTOMINER AANVALSSIMULATIE"
echo "[!] Doel: CPU belasting naar 100% brengen voor $DURATION_SEC seconden"
echo "========================================================"

NUM_CORES=$(nproc)
echo "[+] Gedetecteerde CPU kernen: $NUM_CORES"
echo "[+] Starten van stress worker threads op alle kernen..."

PIDS=()
for ((i=1; i<=NUM_CORES; i++)); do
    # Oneindige wiskundige berekening om CPU volledig te belasten
    ( sha256sum /dev/zero &>/dev/null ) &
    PIDS+=($!)
done

echo "[+] Cryptominer threads actief met PIDs: ${PIDS[*]}"
echo "[+] Monitoring kan nu CPU-piek observeren..."

sleep "$DURATION_SEC"

echo "[+] Simulatie voltooid. Termineren van cryptominer processen..."
for pid in "${PIDS[@]}"; do
    kill -9 "$pid" 2>/dev/null
done

echo "[✓] Cryptominer simulatie gestopt. CPU keert terug naar baseline."
