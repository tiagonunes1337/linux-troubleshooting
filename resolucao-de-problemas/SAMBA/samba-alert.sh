#!/bin/bash

USER="$1"
IP="$2"
SHARE="$3"
WEBHOOK_URL="SUA_URL_DO_WEBHOOK_DO_DISCORD_AQUI"

# Grava um log local para provar que o Samba chamou o script
echo "$(date) - Usuário: $USER | IP: $IP \vert{} Share:$SHARE" >> /tmp/samba-debug.log

MAC=$(ip neigh show | grep "$IP" | awk '{print $5}')
[ -z "$MAC" ] && MAC="Desconhecido"

PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🟢 Acesso SMB Autorizado",
    "color": 3066993,
    "fields": [
      {"name": "Usuario", "value": "\`$USER\`", "inline": true},
      {"name": "IP Origem", "value": "\`$IP\`", "inline": true},
      {"name": "MAC Address", "value": "\`$MAC\`", "inline": true},
      {"name": "Compartilhamento", "value": "\`$SHARE\`", "inline": true},
      {"name": "Horario", "value": "$(date '+%Y-%m-%d %H:%M:%S')", "inline": false}
    ]
  }]
}
EOF
)

# Executa o curl e joga os erros possíveis para um log também
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL" >> /tmp/samba-curl-error.log 2>&1