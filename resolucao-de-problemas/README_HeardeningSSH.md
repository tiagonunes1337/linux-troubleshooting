# 🔐 Configuração e Hardening SSH — Home Lab

Documentação do processo de configuração e endurecimento do acesso SSH em um servidor doméstico Lenovo ThinkCentre, utilizando autenticação por chaves **Ed25519**.

> **Aviso de segurança:** este documento foi preparado para publicação em repositório público. Não contém chaves privadas, senhas, tokens, endereços IP reais ou outras credenciais. Os valores específicos do ambiente são representados por placeholders.

---

## 1. Objetivo

O objetivo inicial deste procedimento foi aumentar a segurança do acesso remoto ao servidor Lenovo ThinkCentre, substituindo a autenticação tradicional por senha por autenticação baseada em **chaves criptográficas assimétricas Ed25519**.

O fluxo planejado consistia em:

1. Gerar pares de chaves SSH utilizando Ed25519 nos dispositivos clientes;
2. Cadastrar as chaves públicas no arquivo `authorized_keys` do servidor;
3. Testar e validar o acesso remoto por chave em cada dispositivo;
4. Desativar a autenticação SSH por senha através de `PasswordAuthentication no`;
5. Restringir o acesso administrativo SSH às chaves autorizadas.

---

## 2. Ambiente

| Componente                 | Descrição                  |
| -------------------------- | -------------------------- |
| **Servidor**               | Lenovo ThinkCentre         |
| **Sistema operacional**    | Linux Mint                 |
| **Serviço**                | OpenSSH                    |
| **Cliente 1**              | PC principal — Linux       |
| **Cliente 2**              | Dispositivo móvel — Termux |
| **Autenticação planejada** | Chaves SSH Ed25519         |

Informações específicas do ambiente, como endereço IP e usuário, não são publicadas.

Exemplos utilizados neste documento:

```text
<USUARIO>
<IP_DO_SERVIDOR>
<CAMINHO_DA_CHAVE>
```

---

# 3. Configuração planejada

## 3.1 Geração das chaves

Para gerar um par de chaves Ed25519 em cada dispositivo cliente:

```bash
ssh-keygen -t ed25519
```

O comando gera normalmente dois arquivos:

```text
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

### Chave privada

```text
id_ed25519
```

A chave privada permanece no dispositivo cliente e **nunca deve ser compartilhada, enviada ao servidor ou publicada no Git**.

### Chave pública

```text
id_ed25519.pub
```

A chave pública pode ser cadastrada no servidor para autorizar o respectivo dispositivo.

### `authorized_keys`

No servidor, as chaves públicas autorizadas ficam normalmente em:

```text
~/.ssh/authorized_keys
```

Cada chave deve ocupar uma única linha no arquivo.

---

## 3.2 Instalação das chaves públicas

A chave pública de cada dispositivo cliente deve ser adicionada ao:

```text
~/.ssh/authorized_keys
```

Exemplo conceitual:

```text
ssh-ed25519 <CHAVE_PUBLICA> <IDENTIFICACAO>
```

A chave privada correspondente permanece exclusivamente no dispositivo cliente.

---

## 3.3 Configuração do OpenSSH

Após cadastrar e validar as chaves, o objetivo é desativar a autenticação SSH tradicional por senha.

A configuração utilizada é:

```text
PasswordAuthentication no
```

A configuração pode estar no arquivo principal:

```text
/etc/ssh/sshd_config
```

ou em arquivos complementares:

```text
/etc/ssh/sshd_config.d/
```

Após alterações na configuração, o serviço SSH pode ser reiniciado:

```bash
sudo systemctl restart ssh
```

> A autenticação por senha somente deve ser desativada após confirmar que o acesso por chave está funcionando.

---

# 4. Incidentes encontrados

Durante a implementação ocorreram alguns problemas relacionados à configuração e sincronização das chaves.

## 4.1 Falha no uso do `ssh-copy-id`

### Problema

A tentativa de utilizar `ssh-copy-id` para enviar a chave pública de um cliente para o servidor falhou.

### Causa

O procedimento dependia de uma forma de autenticação que já não estava disponível após o bloqueio da autenticação por senha.

Como consequência, a tentativa de conexão falhou com:

```text
Permission denied (publickey)
```

### Resultado

Foi necessário utilizar métodos alternativos para cadastrar a chave pública no servidor.

---

## 4.2 Problema de formatação no `authorized_keys`

### Problema

Durante a tentativa de copiar manualmente uma chave pública a partir do Termux para o arquivo `authorized_keys`, a autenticação continuou falhando.

### Causa

Uma chave pública SSH deve permanecer em uma única linha no arquivo `authorized_keys`.

Quebras de linha introduzidas durante o processo de cópia e colagem podem fazer com que o OpenSSH não reconheça corretamente a chave.

### Regra importante

O conteúdo de uma chave pública deve permanecer em uma única linha, por exemplo:

```text
ssh-ed25519 <CHAVE_PUBLICA> <COMENTARIO>
```

---

## 4.3 Sobrescrita de uma chave existente

### Problema

Uma das chaves deixou de funcionar depois que o par criptográfico foi regenerado no cliente.

### Causa

O comando:

```bash
ssh-keygen -t ed25519
```

foi executado novamente e a sobrescrita do arquivo existente foi confirmada.

Isso gerou um novo par de chaves.

Consequentemente, a chave pública anteriormente cadastrada no servidor deixou de corresponder à nova chave privada existente no cliente.

### Lição

Uma chave privada e sua respectiva chave pública formam um par.

Ao substituir a chave privada por uma nova, a chave pública correspondente também muda.

Portanto, qualquer servidor que possua somente a chave pública antiga continuará recusando a nova chave.

---

# 5. Lockout do servidor

## 5.1 Causa

A configuração:

```text
PasswordAuthentication no
```

foi aplicada enquanto os clientes ainda apresentavam problemas relacionados às chaves autorizadas.

Como as chaves disponíveis nos dispositivos clientes não correspondiam corretamente às chaves aceitas pelo servidor, nenhum dos clientes conseguiu concluir a autenticação.

---

## 5.2 Sintoma

Tanto o PC principal quanto o dispositivo utilizando Termux perderam o acesso remoto ao servidor.

Como a autenticação por senha estava desativada, não havia uma segunda forma de autenticação SSH disponível.

---

## 5.3 Erro apresentado

As tentativas de conexão retornavam:

```text
Permission denied (publickey)
```

O resultado foi um **lockout administrativo remoto** do servidor.

---

# 6. Recuperação

A recuperação foi possível porque havia acesso físico ao ThinkCentre.

O procedimento utilizado foi:

1. Acessar diretamente o servidor utilizando teclado e monitor;
2. Abrir o terminal local;
3. Alterar temporariamente a configuração de autenticação;
4. Reativar:

```text
PasswordAuthentication yes
```

5. Reiniciar o serviço SSH:

```bash
sudo systemctl restart ssh
```

6. Recuperar o acesso remoto utilizando autenticação por senha;
7. Retomar a administração do servidor para corrigir as chaves.

> **Importante:** a reativação da autenticação por senha foi uma medida emergencial de recuperação. A configuração final planejada continua sendo a autenticação por chave SSH.

---

# 7. Lições aprendidas

O incidente demonstrou alguns pontos importantes para o processo de hardening.

### Testar antes de bloquear

Nunca desative:

```text
PasswordAuthentication no
```

antes de confirmar que uma chave válida consegue autenticar em uma **nova sessão SSH**.

### Manter uma sessão de recuperação

Durante alterações críticas no SSH, é recomendável manter a sessão administrativa atual aberta enquanto uma segunda sessão é utilizada para testar a nova configuração.

### Cuidado ao regenerar chaves

Executar novamente:

```bash
ssh-keygen -t ed25519
```

e sobrescrever uma chave existente gera um novo par criptográfico.

Servidores que possuem somente a chave pública antiga não reconhecerão automaticamente a nova chave.

### Preservar a integridade do `authorized_keys`

Cada chave pública deve permanecer em uma única linha no arquivo:

```text
~/.ssh/authorized_keys
```

### Ter acesso de recuperação

Alterações na autenticação podem causar perda de acesso remoto.

Por isso, é importante possuir pelo menos uma alternativa de recuperação, como:

* acesso físico;
* console local;
* console remoto;
* outro método administrativo independente do SSH.

### Validar todos os clientes

Antes de desativar a autenticação por senha, todos os dispositivos que precisarão administrar o servidor devem ter suas respectivas chaves testadas.

---

# 8. Estado atual

Após o incidente de lockout, a autenticação por senha foi **reativada temporariamente** para recuperar o controle administrativo do servidor.

A desativação definitiva da autenticação por senha deve ocorrer somente depois que as chaves dos dispositivos autorizados forem:

1. cadastradas corretamente;
2. verificadas no `authorized_keys`;
3. testadas individualmente;
4. confirmadas em novas sessões SSH.

---

# 9. Próximos passos

O procedimento recomendado para concluir o hardening é:

### 1. Verificar a chave atual de cada cliente

```bash
cat ~/.ssh/id_ed25519.pub
```

### 2. Cadastrar as chaves públicas no servidor

Adicionar as chaves correspondentes ao:

```text
~/.ssh/authorized_keys
```

Garantir que cada chave esteja em uma única linha.

### 3. Testar o acesso por chave

A partir de cada cliente:

```bash
ssh <USUARIO>@<IP_DO_SERVIDOR>
```

Se necessário, especificar a chave:

```bash
ssh -i <CAMINHO_DA_CHAVE> <USUARIO>@<IP_DO_SERVIDOR>
```

### 4. Manter a autenticação por senha ativa durante os testes

Isso fornece um mecanismo de recuperação caso alguma chave ainda esteja incorreta.

### 5. Testar uma nova sessão SSH

Confirmar que o acesso por chave funciona antes de alterar a configuração global.

### 6. Desativar a autenticação por senha

Somente após todas as validações:

```text
PasswordAuthentication no
```

### 7. Reiniciar o serviço

```bash
sudo systemctl restart ssh
```

### 8. Realizar a validação final

Confirmar que os dispositivos autorizados conseguem acessar o servidor utilizando exclusivamente suas respectivas chaves.

---

# 10. Boas práticas de segurança

Este documento está preparado para um repositório público.

**Nunca publique:**

* chaves privadas;
* senhas;
* tokens;
* API keys;
* arquivos `.env`;
* credenciais de serviços;
* IPs públicos reais;
* informações de autenticação;
* backups contendo secrets;
* conteúdo sensível de arquivos de configuração.

Antes de realizar um `git push`, revise os arquivos adicionados ao repositório.

---

# 11. Referência

Documentação utilizada como referência para geração de chaves SSH:

**SSH.com — SSH Keygen**

https://www.ssh.com/academy/ssh/keygen

---

## 📌 Resumo

O objetivo deste procedimento foi implementar autenticação SSH baseada em chaves Ed25519 e eliminar a dependência de autenticação por senha.

Durante a implementação ocorreram problemas relacionados ao cadastro, formatação e substituição das chaves, culminando em um lockout remoto quando a autenticação por senha foi desativada.

O acesso foi recuperado através do acesso físico ao ThinkCentre e da reativação temporária da autenticação por senha.

O principal aprendizado do incidente foi que **o hardening da autenticação deve ser realizado somente depois que as chaves forem cadastradas e testadas com sucesso**, mantendo também um método de recuperação disponível para situações de emergência.
