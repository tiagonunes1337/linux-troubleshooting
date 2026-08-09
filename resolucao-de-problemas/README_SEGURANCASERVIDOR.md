# 🖥️ Home Lab & Servidor Doméstico

**Autor:** `<NOME>`
**Hardware:** Lenovo ThinkCentre Edge 72
**Sistema Operacional:** Linux Mint
**Gerenciador de Contêineres:** Docker + CasaOS

---

## 📌 Visão Geral

Este documento descreve a arquitetura, os serviços e as principais medidas de segurança do servidor doméstico.

O objetivo da infraestrutura é prover serviços de mídia, armazenamento e bloqueio de anúncios localmente, com acesso remoto seguro por meio de uma VPN privada, sem exposição direta de serviços à internet pública.

> **Nota de segurança:** informações sensíveis do ambiente real, como endereços IP, credenciais, chaves privadas, tokens e outros segredos, não são armazenadas neste repositório.

---

## 🌐 Rede e Acesso

* **IP Local (LAN):** `<IP_LOCAL>`
* **IP da VPN:** `<IP_VPN>`
* **Port Forwarding (Roteador):** `Desativado`
* **Exposição direta à Internet:** `Nenhuma`

O acesso remoto é realizado exclusivamente através da rede privada da VPN. Não há encaminhamento de portas do roteador para os serviços do servidor.

---

## 🚀 Serviços em Execução (Docker)

| Serviço           | Descrição                                 | Porta                | Acesso Web                |
| :---------------- | :---------------------------------------- | :------------------- | :------------------------ |
| **CasaOS**        | Dashboard e gerenciamento do servidor     | `<PORTA>`            | `http://<IP>:<PORTA>`     |
| **Jellyfin**      | Servidor de mídia                         | `<PORTA>`            | `http://<IP>:<PORTA>`     |
| **Nextcloud**     | Nuvem pessoal e armazenamento de arquivos | `<PORTA>`            | `http://<IP>:<PORTA>`     |
| **AdGuard Home**  | Servidor DNS e bloqueio de anúncios       | `<PORTA_WEB>` / `53` | `http://<IP>:<PORTA_WEB>` |
| **Kasm / Chrome** | Navegador isolado em contêiner            | `<PORTA>`            | `http://<IP>:<PORTA>`     |

> As portas acima podem ser diferentes conforme a configuração do ambiente. Os valores reais não são publicados neste repositório.

---

# 🛡️ Segurança da Informação (Hardening)

A segurança do servidor foi estruturada em diferentes camadas, buscando reduzir a superfície de ataque e impedir a exposição direta dos serviços à Internet.

## 1. Isolamento Externo — VPN

O acesso remoto é realizado exclusivamente através de uma VPN privada.

Não existem portas encaminhadas do roteador para a Internet pública.

Dessa forma, serviços como SSH, CasaOS, Jellyfin, Nextcloud e AdGuard Home não ficam diretamente acessíveis pela WAN.

---

## 2. Firewall Local — UFW

O firewall do sistema utiliza o **UFW (Uncomplicated Firewall)**.

A política padrão para conexões de entrada é:

```text
default deny incoming
```

O acesso aos serviços é permitido somente conforme as regras definidas para as redes e interfaces autorizadas.

Entre os serviços protegidos estão:

* SSH;
* CasaOS;
* Jellyfin;
* Nextcloud;
* AdGuard Home;
* Outros serviços executados pelo ambiente Docker.

As regras específicas não são publicadas neste documento para evitar expor detalhes desnecessários da infraestrutura.

---

## 3. Prevenção de Intrusão — Fail2ban

O `fail2ban` é utilizado para monitorar eventos relacionados à autenticação e aplicar bloqueios temporários quando determinados padrões de comportamento suspeito são identificados.

No caso do SSH, o objetivo é reduzir tentativas automatizadas de autenticação e comportamentos abusivos contra o serviço.

---

# 🔐 4. Hardening do SSH

O acesso administrativo ao servidor utiliza **autenticação por chave pública Ed25519**.

A autenticação SSH tradicional baseada em senha foi desativada através da configuração:

```text
PasswordAuthentication no
```

As chaves públicas autorizadas são armazenadas no mecanismo:

```text
~/.ssh/authorized_keys
```

A chave privada permanece exclusivamente nos dispositivos clientes autorizados e **não deve ser armazenada neste repositório**.

### Geração de uma chave Ed25519

Exemplo:

```bash
ssh-keygen -t ed25519
```

A chave privada deve ser protegida, preferencialmente utilizando uma passphrase.

> A autenticação por chave pública elimina o uso de senhas SSH tradicionais e reduz significativamente o risco de ataques automatizados de tentativa de senha contra o serviço SSH.

---

# ⚠️ 5. Incidente de Lockout SSH

Durante a implementação do hardening do SSH ocorreu um incidente de perda temporária do acesso remoto.

O procedimento realizado foi:

1. Foram geradas chaves SSH nos dispositivos clientes;
2. As chaves públicas foram adicionadas ao servidor;
3. A autenticação por senha foi desativada;
4. O servidor passou a exigir autenticação por chave;
5. As chaves disponíveis no computador principal e no dispositivo móvel utilizado com Termux estavam incorretas ou dessincronizadas devido a substituições anteriores;
6. As tentativas de autenticação falharam;
7. O SSH retornou:

```text
Permission denied (publickey)
```

Como resultado, os dispositivos clientes perderam temporariamente o acesso remoto ao servidor.

---

## 6. Recuperação do acesso

O servidor possuía acesso físico disponível através do próprio ThinkCentre.

Foi utilizado o terminal local para recuperar o acesso.

A configuração:

```text
PasswordAuthentication no
```

foi temporariamente revertida para:

```text
PasswordAuthentication yes
```

Isso permitiu recuperar o acesso utilizando autenticação por senha e retomar o controle administrativo do servidor.

A alteração foi utilizada como **medida de recuperação**, e não como configuração definitiva de segurança.

---

## 7. Lição aprendida

O incidente demonstrou que a autenticação por senha não deve ser desativada antes de confirmar que pelo menos uma chave SSH funcional está sendo aceita pelo servidor.

Antes de aplicar:

```text
PasswordAuthentication no
```

é recomendado:

* gerar a chave;
* instalar a chave pública no servidor;
* testar a autenticação utilizando a nova chave;
* abrir uma segunda sessão SSH e confirmar o acesso;
* manter a sessão administrativa atual aberta durante a alteração;
* possuir um método alternativo de recuperação.

Esse procedimento reduz significativamente o risco de perder o acesso administrativo ao servidor.

---

# ⚠️ 8. Riscos e Pontos Críticos

Apesar das medidas de segurança implementadas, existem riscos de continuidade que precisam ser considerados.

### 1. Perda da chave privada SSH

Se todos os dispositivos autorizados perderem suas respectivas chaves privadas, o acesso SSH poderá ser perdido.

Por isso, as chaves privadas devem ser protegidas e possuir uma estratégia segura de recuperação.

### 2. Ausência de rotina de backup

A infraestrutura ainda depende de uma estratégia adequada de backup.

Em caso de falha física do armazenamento do ThinkCentre, dados e configurações armazenados exclusivamente no servidor poderão ser perdidos.

### 3. Dependência da VPN

O acesso remoto depende da infraestrutura da VPN utilizada.

Caso o serviço de controle ou a conectividade necessária fique indisponível, o acesso remoto poderá ser afetado.

O acesso local continua sendo uma alternativa quando disponível.

### 4. Queda de energia

O servidor depende de alimentação elétrica contínua.

Uma interrupção de energia pode fazer com que serviços hospedados no ThinkCentre fiquem temporariamente indisponíveis.

Como o AdGuard Home fornece DNS para a rede local, uma indisponibilidade do servidor também pode afetar a resolução DNS dos dispositivos que dependem dele.

---

# 🔒 9. Informações que NÃO devem ser publicadas

Este repositório é público. Portanto, nunca devem ser adicionados ao Git:

```text
Chaves privadas SSH
Senhas
Tokens
API Keys
Credenciais do Docker
Credenciais do CasaOS
Credenciais do Nextcloud
Credenciais do Jellyfin
Credenciais do AdGuard
IP público real
Domínios privados
Arquivos .env
Secrets
Backups contendo credenciais
authorized_keys com informações que não devam ser públicas
```

Antes de realizar um `git push`, é importante revisar os arquivos modificados e verificar se nenhum segredo foi incluído.

---

# 📋 10. Checklist de Segurança

* [x] Port forwarding desativado;
* [x] Acesso remoto através de VPN;
* [x] Firewall ativo;
* [x] Política padrão de entrada restritiva;
* [x] Fail2ban configurado;
* [x] SSH utilizando chaves Ed25519;
* [x] Autenticação SSH por senha desativada;
* [ ] Estratégia de backup implementada;
* [ ] Estratégia de recuperação das chaves definida;
* [ ] Monitoramento dos serviços implementado.

---

# 📚 11. Referência

Documentação utilizada para geração e gerenciamento de chaves SSH:

**SSH.com — SSH Keygen**

https://www.ssh.com/academy/ssh/keygen

---

## 📌 Resumo

Este Home Lab utiliza um servidor Lenovo ThinkCentre Edge 72 executando Linux Mint, Docker e CasaOS para hospedar serviços de mídia, armazenamento, DNS e outras aplicações.

A infraestrutura foi configurada priorizando o acesso privado através de VPN, firewall local e hardening do SSH.

Durante a implementação do acesso SSH baseado em Ed25519 ocorreu um lockout devido à dessincronização das chaves dos dispositivos clientes após a desativação da autenticação por senha.

O acesso foi recuperado através do terminal físico do servidor, permitindo corrigir a configuração antes de prosseguir com o hardening.

O incidente reforçou a importância de **validar uma chave SSH funcional antes de desativar completamente a autenticação por senha e manter sempre um método de recuperação administrativa**.
