#!/bin/bash

# =============================================================================
# check_ssh_security.sh
#
# Monitoramento de segurança SSH - últimas 48 horas
#
# Informações:
#   - Logins aceitos
#   - Tentativas falhas
#   - IP
#   - MAC para dispositivos da rede local
#   - Localização aproximada de IPs públicos
#   - Usuário
#   - Método de autenticação
#   - Dispositivo/hostname quando disponível
#   - Fail2ban
#
# Compatível com Ubuntu/Debian
# =============================================================================

# ----------------------------- CORES ------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ----------------------------- CONFIG -----------------------------------------

HOURS=48

# Arquivo temporário
TMP_DIR="/tmp/ssh_security_check_$$"
mkdir -p "$TMP_DIR"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

# ----------------------------- FUNÇÕES ----------------------------------------

separator() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

header() {
    echo ""
    separator
    echo -e "${BOLD}  $1${RESET}"
    separator
}

is_private_ip() {
    local ip="$1"

    [[ "$ip" =~ ^10\. ]] && return 0
    [[ "$ip" =~ ^192\.168\. ]] && return 0
    [[ "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] && return 0
    [[ "$ip" =~ ^127\. ]] && return 0

    return 1
}

get_mac() {
    local ip="$1"

    if command -v ip &>/dev/null; then
        local mac

        mac=$(ip neigh show "$ip" 2>/dev/null | awk '
            /lladdr/ {
                for (i=1; i<=NF; i++) {
                    if ($i == "lladdr") {
                        print $(i+1)
                        exit
                    }
                }
            }
        ')

        if [ -n "$mac" ]; then
            echo "$mac"
        else
            echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

get_hostname() {
    local ip="$1"

    local hostname

    hostname=$(getent hosts "$ip" 2>/dev/null | awk '{print $2}' | head -n1)

    if [ -n "$hostname" ]; then
        echo "$hostname"
    else
        echo "N/A"
    fi
}

get_location() {
    local ip="$1"

    # IPs privados não possuem localização pública.
    if is_private_ip "$ip"; then
        echo "Rede local"
        return
    fi

    # localhost / inválidos
    if [[ "$ip" == "127."* || "$ip" == "::1" ]]; then
        echo "Localhost"
        return
    fi

    # API externa de geolocalização.
    # Timeout curto para não travar o relatório.
    if command -v curl &>/dev/null; then

        local result

        result=$(curl -s --max-time 4 \
            "http://ip-api.com/json/$ip?fields=status,country,regionName,city,isp" \
            2>/dev/null)

        if echo "$result" | grep -q '"status":"success"'; then

            local country
            local region
            local city
            local isp

            country=$(echo "$result" | sed -n 's/.*"country":"\([^"]*\)".*/\1/p')
            region=$(echo "$result" | sed -n 's/.*"regionName":"\([^"]*\)".*/\1/p')
            city=$(echo "$result" | sed -n 's/.*"city":"\([^"]*\)".*/\1/p')
            isp=$(echo "$result" | sed -n 's/.*"isp":"\([^"]*\)".*/\1/p')

            echo "$city / $region / $country | ISP: $isp"
        else
            echo "Não identificada"
        fi
    else
        echo "curl não instalado"
    fi
}

get_device() {
    local ip="$1"

    local hostname

    hostname=$(get_hostname "$ip")

    if [ "$hostname" != "N/A" ]; then
        echo "$hostname"
    else
        if is_private_ip "$ip"; then
            echo "Dispositivo da rede local"
        else
            echo "Dispositivo remoto não identificado"
        fi
    fi
}

# ----------------------------- LOG --------------------------------------------

header "🔐 SSH SECURITY CHECK — ÚLTIMAS ${HOURS} HORAS"

echo -e "${YELLOW}  Período analisado:${RESET}"

if command -v date &>/dev/null; then
    START_TIME=$(date -d "-${HOURS} hours" '+%Y-%m-%d %H:%M:%S')
    END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    echo "  De: $START_TIME"
    echo "  Até: $END_TIME"
fi

echo ""
echo -e "${YELLOW}  Observação:${RESET}"
echo "  MAC só pode ser obtido para dispositivos diretamente acessíveis"
echo "  pela rede local. IPs públicos não possuem MAC disponível no servidor."
echo ""

# ----------------------------- DETECTAR LOG -----------------------------------

USE_JOURNALCTL=false

if command -v journalctl &>/dev/null; then
    if sudo journalctl -u ssh --since "48 hours ago" --no-pager -n 1 &>/dev/null; then
        USE_JOURNALCTL=true
    elif sudo journalctl -u sshd --since "48 hours ago" --no-pager -n 1 &>/dev/null; then
        USE_JOURNALCTL=true
        SSH_SERVICE="sshd"
    fi
fi

if [ "$USE_JOURNALCTL" = true ] && [ -z "$SSH_SERVICE" ]; then
    SSH_SERVICE="ssh"
fi

# ----------------------------- COLETAR LOGS -----------------------------------

if [ "$USE_JOURNALCTL" = true ]; then

    sudo journalctl \
        -u "$SSH_SERVICE" \
        --since "48 hours ago" \
        --no-pager \
        > "$TMP_DIR/ssh.log"

else

    if [ -f /var/log/auth.log ]; then

        sudo awk '
        {
            print
        }
        ' /var/log/auth.log > "$TMP_DIR/ssh.log"

    else

        echo -e "${RED}✖ Não foi possível encontrar os logs SSH.${RESET}"
        exit 1

    fi
fi

# ----------------------------- LOGINS ACEITOS ---------------------------------

header "1/4 🟢 LOGINS ACEITOS NAS ÚLTIMAS 48H"

ACCEPTED=$(grep -E "Accepted (password|publickey|keyboard-interactive)" \
    "$TMP_DIR/ssh.log" 2>/dev/null)

ACCEPTED_COUNT=0

if [ -z "$ACCEPTED" ]; then

    echo -e "${GREEN}  ✔ Nenhum login SSH aceito nas últimas 48 horas.${RESET}"

else

    ACCEPTED_COUNT=$(echo "$ACCEPTED" | wc -l)

    echo -e "${GREEN}  ✔ $ACCEPTED_COUNT login(s) aceito(s).${RESET}"
    echo ""

    while IFS= read -r line; do

        # Extrai IP
        IP=$(echo "$line" | sed -n 's/.*from \([^ ]*\).*/\1/p')

        # Extrai usuário
        USER=$(echo "$line" | sed -n 's/.*Accepted [^ ]* for \([^ ]*\) from.*/\1/p')

        # Método
        METHOD=$(echo "$line" | sed -n 's/.*Accepted \([^ ]*\).*/\1/p')

        # Porta
        PORT=$(echo "$line" | sed -n 's/.* port \([0-9]*\).*/\1/p')

        if [ -z "$IP" ]; then
            IP="N/A"
        fi

        if [ -z "$USER" ]; then
            USER="N/A"
        fi

        if [ -z "$METHOD" ]; then
            METHOD="N/A"
        fi

        if [ -z "$PORT" ]; then
            PORT="N/A"
        fi

        MAC=$(get_mac "$IP")
        HOSTNAME=$(get_hostname "$IP")
        LOCATION=$(get_location "$IP")
        DEVICE=$(get_device "$IP")

        echo -e "${BOLD}┌─ LOGIN ACEITO${RESET}"
        echo "│ Data/Hora : $(echo "$line" | cut -d' ' -f1-3)"
        echo "│ Usuário   : $USER"
        echo "│ IP        : $IP"
        echo "│ MAC       : $MAC"
        echo "│ Método    : $METHOD"
        echo "│ Porta     : $PORT"
        echo "│ Hostname  : $HOSTNAME"
        echo "│ Dispositivo: $DEVICE"
        echo "│ Localização: $LOCATION"
        echo -e "${BOLD}└────────────────────────────────────────────────────────────${RESET}"
        echo ""

    done <<< "$ACCEPTED"

fi

# ----------------------------- FALHAS -----------------------------------------

header "2/4 🔴 TENTATIVAS DE LOGIN FALHAS — ÚLTIMAS 48H"

FAILED=$(grep -E "Failed password|authentication failure|Invalid user" \
    "$TMP_DIR/ssh.log" 2>/dev/null)

FAILED_COUNT=0

if [ -z "$FAILED" ]; then

    echo -e "${GREEN}  ✔ Nenhuma tentativa falha encontrada.${RESET}"

else

    FAILED_COUNT=$(echo "$FAILED" | wc -l)

    echo -e "${RED}  ⚠ $FAILED_COUNT tentativa(s) falha(s).${RESET}"
    echo ""

    while IFS= read -r line; do

        IP=$(echo "$line" | sed -n 's/.*from \([^ ]*\).*/\1/p')

        USER=$(echo "$line" | sed -n \
            -e 's/.*Failed password for invalid user \([^ ]*\) from.*/\1/p' \
            -e 's/.*Failed password for \([^ ]*\) from.*/\1/p' \
            -e 's/.*Invalid user \([^ ]*\) from.*/\1/p' | head -n1)

        if [ -z "$IP" ]; then
            IP="N/A"
        fi

        if [ -z "$USER" ]; then
            USER="N/A"
        fi

        MAC=$(get_mac "$IP")
        HOSTNAME=$(get_hostname "$IP")
        LOCATION=$(get_location "$IP")
        DEVICE=$(get_device "$IP")

        echo -e "${RED}┌─ TENTATIVA FALHA${RESET}"
        echo "│ Data/Hora : $(echo "$line" | cut -d' ' -f1-3)"
        echo "│ Usuário   : $USER"
        echo "│ IP        : $IP"
        echo "│ MAC       : $MAC"
        echo "│ Hostname  : $HOSTNAME"
        echo "│ Dispositivo: $DEVICE"
        echo "│ Localização: $LOCATION"
        echo -e "${RED}└────────────────────────────────────────────────────────────${RESET}"
        echo ""

    done <<< "$FAILED"

fi

# ----------------------------- RESUMO POR IP ----------------------------------

header "3/4 📊 RESUMO POR IP"

ALL_IPS=$(grep -E "Accepted |Failed password|Invalid user" \
    "$TMP_DIR/ssh.log" 2>/dev/null |
    grep -oE "from [0-9a-fA-F:.]+" |
    awk '{print $2}' |
    sort -u)

if [ -z "$ALL_IPS" ]; then

    echo -e "${GREEN}  Nenhum IP SSH registrado nas últimas 48 horas.${RESET}"

else

    printf "%-20s %-8s %-8s %-20s\n" "IP" "ACEITOS" "FALHAS" "ORIGEM"
    echo "--------------------------------------------------------------------------"

    while IFS= read -r IP; do

        SUCCESS=$(echo "$ACCEPTED" | grep -c "from $IP " 2>/dev/null)
        FAIL=$(echo "$FAILED" | grep -c "from $IP " 2>/dev/null)

        if [ -z "$SUCCESS" ]; then SUCCESS=0; fi
        if [ -z "$FAIL" ]; then FAIL=0; fi

        if is_private_ip "$IP"; then
            ORIGIN="Rede local"
        else
            ORIGIN="Internet"
        fi

        printf "%-20s %-8s %-8s %-20s\n" \
            "$IP" "$SUCCESS" "$FAIL" "$ORIGIN"

    done <<< "$ALL_IPS"

fi

echo ""

# ----------------------------- FAIL2BAN ---------------------------------------

header "4/4 🛡️ STATUS DO FAIL2BAN"

if command -v fail2ban-client &>/dev/null; then

    if sudo fail2ban-client status sshd &>/dev/null; then

        sudo fail2ban-client status sshd

    else

        echo -e "${YELLOW}  Fail2ban instalado, mas a jail 'sshd' não está disponível.${RESET}"

        echo ""
        echo "  Jails disponíveis:"
        sudo fail2ban-client status 2>/dev/null

    fi

else

    echo -e "${RED}  ✖ Fail2ban não está instalado.${RESET}"

fi

# ----------------------------- RESUMO FINAL -----------------------------------

header "📋 RESUMO DE SEGURANÇA"

echo "  Período analisado : últimas ${HOURS} horas"
echo "  Logins aceitos    : $ACCEPTED_COUNT"
echo "  Tentativas falhas : $FAILED_COUNT"

echo ""

if [ "$ACCEPTED_COUNT" -eq 0 ]; then

    echo -e "${GREEN}  ✔ Nenhum acesso SSH realizado no período.${RESET}"

else

    echo -e "${GREEN}  ✔ Houve $ACCEPTED_COUNT acesso(s) SSH bem-sucedido(s).${RESET}"

fi

if [ "$FAILED_COUNT" -eq 0 ]; then

    echo -e "${GREEN}  ✔ Nenhuma tentativa de autenticação falhou.${RESET}"

else

    echo -e "${RED}  ⚠ Foram registradas $FAILED_COUNT tentativa(s) de acesso falha(s).${RESET}"

fi

echo ""
echo -e "${YELLOW}  IMPORTANTE:${RESET}"
echo "  • Localização por IP é aproximada."
echo "  • MAC só é identificado na rede local."
echo "  • O SSH normalmente não informa o modelo do dispositivo cliente."
echo "  • 'Dispositivo' é baseado em hostname/rede quando disponível."
echo ""

separator
echo -e "${BOLD}  FIM DO RELATÓRIO${RESET}"
separator

echo ""
echo -e "Execute novamente com:"
echo -e "${CYAN}sudo bash checksshsecurity.sh${RESET}"
echo ""