# Script de Teste de Autenticação SSH por Chave

Este documento descreve o uso do script `teste-ssh.sh` para validar se a autenticação via chave pública SSH está funcionando corretamente entre o cliente local e o servidor remoto, sem risco de bloqueio acidental de acesso.

## Objetivo

O script tenta estabelecer uma conexão usando exclusivamente o método de chave pública, forçando `PreferredAuthentications=publickey` e evitando o fallback para senha.

## Pré-requisitos

- O cliente deve possuir um par de chaves SSH, como `id_ed25519` e `id_ed25519.pub`, na pasta `~/.ssh/`.
- A chave pública `.pub` deve estar cadastrada no arquivo `~/.ssh/authorized_keys` do usuário no servidor.
- O serviço OpenSSH deve estar ativo e acessível na rede local ou via VPN, como Tailscale.

## Como configurar e executar

### 1. Dar permissão de execução ao script

No terminal do cliente, navegue até a pasta onde o script foi salvo e execute:

```bash
chmod +x teste-ssh.sh
```

### 2. Editar a variável do servidor

Abra o arquivo `teste-ssh.sh` com um editor de texto, como `nano` ou `vim`, e substitua a variável `SERVER` pelos dados corretos do servidor:

```bash
SERVER="usuario@100.x.y.z"   # Substitua pelo usuário e IP do seu servidor
```

### 3. Executar o teste

Rode o script diretamente no terminal:

```bash
./teste-ssh.sh
```

## Entendendo os resultados

### ✅ Sucesso

- **Código de saída:** `0`
- **Mensagem esperada:** `OK: autenticação SSH por chave funcionou.`

Isso indica que o cliente enviou a chave privada, o servidor reconheceu a chave pública no `authorized_keys` e autorizou o acesso sem pedir a senha da conta.

> Próximo passo: somente após essa confirmação é seguro considerar a desativação da autenticação por senha em `/etc/ssh/sshd_config`.

### ❌ Falha

- **Código de saída:** maior que `0`
- **Mensagem esperada:** `FALHA: autenticação por chave não foi concluída.`

Isso geralmente indica que o servidor recusou a chave. O modo verbose (`ssh -v`) pode exibir detalhes adicionais no terminal.

### Causas comuns

- A chave pública não foi copiada corretamente para `~/.ssh/authorized_keys` no servidor.
- As permissões de arquivo estão incorretas no servidor; a pasta `~/.ssh` deve ter permissão `700` e o arquivo `authorized_keys` deve ter permissão `600`.
- O nome do usuário ou o endereço IP informados na variável `SERVER` estão incorretos.

## Importante

NUNCA desative `PasswordAuthentication` no servidor enquanto o script `teste-ssh.sh` não retornar a confirmação `OK`. O script foi projetado como um teste não destrutivo para evitar bloqueios acidentais (lockout).