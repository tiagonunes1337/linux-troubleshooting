#!/usr/bin/env bash

SERVER="######(nomedoservidor)@xxx.xxx.xx.xxx(IPSERVIDOR)"

echo "========================================="
echo "   TESTE DE AUTENTICAÇÃO SSH POR CHAVE"
echo "========================================="
echo
echo "Servidor: $SERVER"
echo
echo "[1/3] Chaves SSH disponíveis no cliente:"
ls -lah ~/.ssh/ 2>/dev/null | grep -E 'id_.*|authorized_keys' || {
    echo "Nenhuma chave SSH encontrada em ~/.ssh/"
}
echo
echo "-----------------------------------------"
echo "[2/3] Testando autenticação por chave..."
echo "-----------------------------------------"
echo
echo "IMPORTANTE:"
echo "- Este teste NÃO altera o servidor."
echo "- Se a chave estiver configurada corretamente,"
echo "  a autenticação deverá ocorrer sem senha da conta."
echo
read -rp "Pressione ENTER para iniciar o teste..."
echo

ssh -v \
    -o PreferredAuthentications=publickey \
    -o PasswordAuthentication=no \
        "$SERVER"

STATUS=$?

echo
echo "-----------------------------------------"
echo "[3/3] Resultado"
echo "-----------------------------------------"

if [ "$STATUS" -eq 0 ]; then
    echo "OK: autenticação SSH por chave funcionou."
    echo
    echo "O cliente conseguiu acessar o servidor utilizando"
    echo "autenticação por chave pública."
else
    echo "FALHA: autenticação por chave não foi concluída."
    echo
    echo "Código de saída: $STATUS"
    echo
    echo "NÃO desative PasswordAuthentication ainda."
    echo "Primeiro corrija a chave e repita o teste."
fi