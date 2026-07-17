# Guia de Resolução de Problemas: Linux & Discos (Steam Library)

Este repositório contém as soluções práticas para problemas comuns de infraestrutura e permissões que encontrei durante minha jornada com o Linux. O objetivo é servir como uma base de conhecimento rápida para quem está começando.

**Testado em:** Ubuntu 26.04 LTS / Steam para Linux

## Índice
- [Problema: SSD ou HD não é reconhecido](#problema-ssd-ou-hd-não-é-reconhecido-como-biblioteca-steam-erro-de-permissões)
- [Troubleshooting](#troubleshooting-ainda-não-funciona)
- [Dicas de Infraestrutura](#dicas-de-infraestrutura-para-iniciantes)

---

## Problema: SSD ou HD não é reconhecido como Biblioteca Steam (Erro de Permissões)

### O Cenário
Você conecta um SSD ou HD externo/secundário, o sistema o monta automaticamente, mas a Steam se recusa a criar uma biblioteca de jogos nele, alegando falta de permissão ou não permitindo que a unidade seja selecionada.

### O Diagnóstico
O problema, na maioria das vezes, é que o sistema montou o disco com permissões restritas (apenas leitura para o usuário atual ou dono como `root`), impedindo que a Steam grave arquivos. Além disso, a Steam exige que a biblioteca seja uma pasta específica (geralmente `steamapps`) dentro do diretório.

### Passo a Passo da Solução

1.  **Identificar o Ponto de Montagem:**
    Verifique onde o disco está montado:
    ```bash
    lsblk
    ```
    *(Procure na coluna MOUNTPOINTS o caminho do seu disco, ex: `/run/media/seu-usuario/disco`)*

2.  **Verificar Permissões:**
    Liste os detalhes do diretório para checar quem é o dono:
    ```bash
    ls -ld /caminho/do/seu/disco
    ```
    Se aparecer `drwxrwx---` ou o dono for `root`, o acesso será negado.

3.  **Ajustar Permissões (Modo prático):**
    Dê permissão total (leitura, escrita e execução) para o seu usuário:
    ```bash
    sudo chmod 755 /caminho/do/seu/disco
    ```
    > **Nota de Segurança:** Evitar `chmod 777` é uma boa prática! O `755` permite leitura/execução para todos, mas apenas o dono pode escrever. Se quiser ser mais restritivo, use `750` ou configure um grupo específico.

4.  **Criar Estrutura Necessária:**
    A Steam não aceita a raiz do disco. Crie uma subpasta organizada:
    ```bash
    cd /caminho/do/seu/disco
    mkdir -p SteamLibrary/steamapps
    ```

5.  **Corrigir o Dono:**
    Garanta que o seu usuário tenha controle total sobre a pasta criada:
    ```bash
    sudo chown -R $USER:$USER /caminho/do/seu/disco/SteamLibrary
    ```

6.  **Configurar Montagem Automática (fstab):**
    Para que o disco não "suma" ou perca as permissões ao reiniciar:
    *   Pegue o UUID do disco: `lsblk -f`
    *   Edite o arquivo `fstab`: `sudo nano /etc/fstab`
    *   Adicione a linha: `UUID=seu-uuid-aqui /caminho/do/disco ext4 defaults,uid=1000,gid=1000,umask=0022 0 2`
    *   Salve e recarregue: `sudo systemctl daemon-reload` e `sudo mount -a`
    
    > Os parâmetros `uid=1000,gid=1000` garantem que o disco é de propriedade do seu usuário (uid 1000 é tipicamente o primeiro usuário não-root no Ubuntu).

---

## Troubleshooting: Ainda Não Funciona?

### "UUID not found" ou disco não aparece em `lsblk`
- **Solução:** O disco pode não estar formatado ou precisa ser montado manualmente
  ```bash
  sudo fdisk -l  # lista todos os discos
  sudo mount /dev/sdX1 /mnt/disco  # monta manualmente
  ```

### A Steam ainda não reconhece a biblioteca após as mudanças
- **Solução:** Reinicie a Steam completamente
  ```bash
  killall steam
  steam &
  ```
- Se persistir, verifique se a pasta `/SteamLibrary/steamapps` existe e tem permissão de escrita:
  ```bash
  ls -ld /caminho/do/seu/disco/SteamLibrary/steamapps
  touch /caminho/do/seu/disco/SteamLibrary/steamapps/test.txt  # testa escrita
  rm /caminho/do/seu/disco/SteamLibrary/steamapps/test.txt
  ```

### Disco desaparece ou perde permissões após reiniciar
- **Solução:** Configure corretamente o `fstab` (passo 6 acima)
- Verifique se a montagem automática funcionou:
  ```bash
  mount | grep seu-disco  # deve aparecer na lista
  ```

### Erro "Permission denied" ao criar pasta
- **Solução:** Verifique quem é o dono do disco
  ```bash
  ls -ld /caminho/do/seu/disco
  whoami  # seu usuário
  ```
- Se o dono for `root`, altere:
  ```bash
  sudo chown -R $USER:$USER /caminho/do/seu/disco
  ```

---

## Dicas de Infraestrutura para Iniciantes
*   **O terminal é seu melhor amigo:** Sempre que algo não funcionar, verifique os logs. `dmesg -w` em tempo real pode mostrar exatamente o erro de I/O ou permissão que o sistema está bloqueando.
*   **Não entre em pânico:** Erros de sistema são, na verdade, dados. Analise a mensagem, procure a causa (se é permissão, hardware ou caminho) e documente a solução.
*   **Documente sempre:** Se resolveu, escreva. Você não vai lembrar como consertou isso daqui a 6 meses.
*   **Permissões são tudo:** No Linux, é melhor ser restritivo e abrir depois do que abrir para tudo. Use `chmod 755`, não `777`.
*   **Backup primeiro:** Antes de mexer com `fstab`, faça backup: `sudo cp /etc/fstab /etc/fstab.backup`

---

**Última atualização:** 2026-07-16 | **Versão do Ubuntu:** 26.04 LTS