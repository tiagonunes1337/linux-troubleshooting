#!/usr/bin/env bash
# ==============================================================================
# Script: check_steam_ntfs.sh
# Descrição: Ferramenta de diagnóstico para validação de ambiente Steam em NTFS
# Objetivo: Auditar permissões, flags de montagem e symlinks para o Proton.
# ==============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Caminho alvo padrão (pode ser passado como argumento)
TARGET_MOUNT=${1:-"/mnt/jogos_steam"}
SYMLINK_TARGET="$TARGET_MOUNT/SteamLibrary/steamapps"

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}  Auditoria de Partição NTFS para Steam/Proton      ${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# 1. Verifica dependências básicas
if ! command -v findmnt &> /dev/null; then
    echo -e "${RED}[ERRO] Pacote 'util-linux' (findmnt) não encontrado.${NC}"
    exit 1
fi

# 2. Verifica se a partição está montada
echo -n "1. Verificando ponto de montagem: "
if findmnt "$TARGET_MOUNT" > /dev/null; then
    echo -e "${GREEN}[OK] O diretório $TARGET_MOUNT está montado.${NC}"
else
    echo -e "${RED}[FALHA] O diretório $TARGET_MOUNT não está montado.${NC}"
    echo -e "   -> Dica: Verifique seu /etc/fstab e rode 'sudo mount -a'"
    exit 1
fi

# 3. Verifica o driver utilizado
DRIVER=$(findmnt -n -o FSTYPE "$TARGET_MOUNT")
echo -n "2. Verificando Driver NTFS: "
if [[ "$DRIVER" == "ntfs3" || "$DRIVER" == "fuseblk" ]]; then
    echo -e "${GREEN}[OK] Utilizando driver compatível: $DRIVER${NC}"
else
    echo -e "${YELLOW}[AVISO] Sistema de arquivos não é ntfs3 ou ntfs-3g (Detectado: $DRIVER).${NC}"
fi

# 4. Verifica permissão de Leitura e Escrita (RW) e flags
echo "3. Analisando flags de montagem:"
MOUNT_OPTIONS=$(findmnt -n -o OPTIONS "$TARGET_MOUNT")

if [[ "$MOUNT_OPTIONS" == *"rw"* ]]; then
    echo -e "   ${GREEN}[OK] Partição em modo Leitura/Escrita (rw)${NC}"
else
    echo -e "   ${RED}[FALHA] Partição em modo Somente Leitura (ro).${NC}"
fi

if [[ "$MOUNT_OPTIONS" != *"noexec"* ]]; then
    echo -e "   ${GREEN}[OK] Permissão de execução ativada (exec)${NC}"
else
    echo -e "   ${RED}[FALHA] Faltando flag 'exec' (Obrigatório para o Proton jogar)${NC}"
fi

if [[ "$DRIVER" == "ntfs3" && "$MOUNT_OPTIONS" != *"nocase"* ]]; then
    echo -e "   ${YELLOW}[ALERTA] Driver ntfs3 detectado, mas flag 'nocase' está ausente. Isso causará conflitos de diretórios na Steam.${NC}"
fi

# 5. Validação de bloqueio do Windows (Fast Startup)
echo -n "4. Verificando bloqueios de sistema Windows: "
if [ -f "$TARGET_MOUNT/hiberfil.sys" ]; then
    echo -e "${RED}[ALERTA CRÍTICO] hiberfil.sys encontrado!${NC}"
    echo -e "   -> O Windows está em estado hibernado/Fast Startup."
    echo -e "   -> Isso força o Linux a montar em Read-Only ou corromper arquivos."
    echo -e "   -> Solução: Faça boot no Windows, rode 'powercfg.exe /hibernate off' no CMD e reinicie."
else
    echo -e "${GREEN}[OK] Arquivo de hibernação não detectado.${NC}"
fi

# 6. Teste Real de Escrita
echo -n "5. Testando I/O Real no diretório: "
TEST_FILE="$TARGET_MOUNT/test_proton_io.tmp"
if touch "$TEST_FILE" 2>/dev/null; then
    rm "$TEST_FILE"
    echo -e "${GREEN}[OK] Operação de Escrita confirmada.${NC}"
else
    echo -e "${RED}[FALHA] Permissão negada pelo sistema de arquivos.${NC}"
fi

# 7. Verifica Symlink da SteamLibrary
echo -n "6. Validando Symlink da Steam: "
if [ -L "$SYMLINK_TARGET" ]; then
    if [ -e "$SYMLINK_TARGET" ]; then
        echo -e "${GREEN}[OK] Symlink válido apontando para a pasta original.${NC}"
    else
        echo -e "${RED}[FALHA] Symlink quebrado (Broken link). O diretório de origem não existe.${NC}"
    fi
else
    echo -e "${YELLOW}[AVISO] Symlink não encontrado em $SYMLINK_TARGET${NC}"
    echo -e "   -> Se a Steam não reconhecer os jogos, crie o atalho apontando para 'Program Files (x86)/Steam/steamapps'"
fi

echo -e "\n${CYAN}====================================================${NC}"
echo -e "Auditoria finalizada. Revise os alertas em Vermelho e Amarelo."