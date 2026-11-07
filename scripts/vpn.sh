#!/usr/bin/env bash

echo "Conectando a UPClink VPN..."
echo "Se abrirá el navegador para autenticación SAML."
echo ""

LOG_FILE=$(mktemp)
trap "rm -f $LOG_FILE" EXIT

sudo openfortivpn myupclink.upc.edu:443 --saml-login >"$LOG_FILE" 2>&1 &
VPN_PID=$!

for i in {1..15}; do
    sleep 1
    URL=$(grep -oE 'https://[^[:space:]]+' "$LOG_FILE" 2>/dev/null | head -1)
    if [ -n "$URL" ]; then
        echo "Abriendo navegador..."
        xdg-open "$URL" 2>/dev/null
        break
    fi
done

echo "Autentícate en el navegador. Presiona Ctrl+C para desconectar."
echo ""

tail -f "$LOG_FILE" 2>/dev/null &
TAIL_PID=$!

wait $VPN_PID 2>/dev/null
kill $TAIL_PID 2>/dev/null
