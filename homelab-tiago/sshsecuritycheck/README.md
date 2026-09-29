# 🔐 SSH Security Check

Script de monitoramento e auditoria de segurança SSH para servidores Linux Ubuntu/Debian.

O script analisa as **últimas 48 horas** e apresenta um relatório resumido dos acessos SSH realizados no servidor, incluindo logins aceitos, tentativas de autenticação falhas, origem dos IPs e status do Fail2ban.

---

## 📋 O que o script verifica

| # | Verificação          | Informações                                         |
| - | -------------------- | --------------------------------------------------- |
| 1 | 🟢 Logins aceitos    | Usuário, IP, data/hora, método e porta              |
| 2 | 🔴 Tentativas falhas | IP, usuário tentado e data/hora                     |
| 3 | 📊 Resumo por IP     | Quantidade de acessos aceitos e falhos              |
| 4 | 🛡️ Fail2ban         | IPs bloqueados e estatísticas da jail SSH           |
| — | 🌐 Enriquecimento    | MAC, hostname, dispositivo e localização aproximada |

---

## 🚀 Como usar

### 1. Dar permissão de execução

Execute apenas uma vez:

```bash
chmod +x checksshsecurity.sh
```

### 2. Executar

```bash
sudo bash checksshsecurity.sh
```

O relatório analisará automaticamente os eventos registrados nas **últimas 48 horas**.

---

## 🔎 Exemplo de relatório

Um acesso SSH poderá aparecer aproximadamente assim:

```text
┌─ LOGIN ACEITO
│ Data/Hora : Aug 10 08:32:15
│ Usuário   : servidor
│ IP        : 192.168.15.20
│ MAC       : 24:4b:fe:xx:xx:xx
│ Método    : publickey
│ Porta     : 52134
│ Hostname  : notebook
│ Dispositivo: notebook
│ Localização: Rede local
└────────────────────────────────────────────────────────────
```

Para um IP público:

```text
┌─ TENTATIVA FALHA
│ Data/Hora : Aug 10 03:21:42
│ Usuário   : root
│ IP        : 203.0.113.42
│ MAC       : N/A
│ Hostname  : N/A
│ Dispositivo: Dispositivo remoto não identificado
│ Localização: São Paulo / São Paulo / Brazil | ISP: Example ISP
└────────────────────────────────────────────────────────────
```

---

## 🧑‍💻 Identificação do dispositivo

O script tenta identificar o dispositivo utilizando informações disponíveis na rede e no sistema.

A identificação pode utilizar:

* IP;
* endereço MAC;
* hostname;
* rede local;
* informações disponíveis no log SSH.

### ⚠️ Limitação importante

O SSH **não informa diretamente o modelo do computador ou celular que realizou o acesso**.

Por exemplo, o servidor pode saber que:

```text
192.168.15.20
```

realizou uma conexão, mas isso não significa que ele consiga determinar automaticamente:

```text
Samsung Galaxy
iPhone
Dell Inspiron
Lenovo ThinkCentre
```

Por isso, o campo `Dispositivo` é uma identificação aproximada baseada nas informações disponíveis.

---

## 🏠 Identificação do MAC

Para dispositivos da rede local, o script consulta a tabela de vizinhança do Linux:

```bash
ip neigh
```

Exemplo:

```text
192.168.15.20 dev enp3s0 lladdr 24:4b:fe:xx:xx:xx REACHABLE
```

Nesse caso, o script consegue apresentar:

```text
MAC: 24:4b:fe:xx:xx:xx
```

### Por que IP público não possui MAC?

O endereço MAC funciona na rede local e não é transportado pela Internet até o servidor.

Portanto:

```text
192.168.15.20 → pode ter MAC identificado
```

mas:

```text
8.8.8.8 → MAC do computador remoto não pode ser obtido pelo servidor
```

Nesse caso será apresentado:

```text
MAC: N/A
```

---

## 🌎 Localização por IP

Para IPs públicos, o script pode consultar uma API de geolocalização para obter uma localização aproximada.

O resultado pode apresentar:

```text
Cidade / Estado / País | ISP
```

Por exemplo:

```text
São Paulo / São Paulo / Brazil | ISP: Example ISP
```

### ⚠️ A localização não é exata

A geolocalização por IP **não deve ser interpretada como GPS**.

Um IP pode estar registrado em:

* outra cidade;
* outra região;
* data center;
* sede da operadora;
* infraestrutura de VPN;
* servidor proxy;
* CDN.

Portanto, a localização deve ser utilizada apenas como **indicador de origem**.

---

## 🟢 Logins aceitos

O relatório procura eventos como:

```text
Accepted publickey for servidor from 192.168.15.20
```

Isso indica que uma autenticação SSH foi concluída com sucesso.

O relatório apresenta:

* data e hora;
* usuário;
* IP;
* MAC, quando disponível;
* método de autenticação;
* porta;
* hostname;
* dispositivo;
* localização aproximada.

### Métodos comuns

```text
publickey
```

Autenticação utilizando chave SSH.

```text
password
```

Autenticação utilizando senha.

Em uma configuração de segurança mais rígida, normalmente é preferível utilizar:

```text
publickey
```

e desabilitar autenticação por senha quando isso for compatível com o ambiente.

---

## 🔴 Tentativas falhas

O script também procura eventos como:

```text
Failed password
Invalid user
authentication failure
```

Exemplo:

```text
┌─ TENTATIVA FALHA
│ Data/Hora : Aug 10 03:21:42
│ Usuário   : root
│ IP        : 203.0.113.42
│ MAC       : N/A
│ Hostname  : N/A
│ Dispositivo: Dispositivo remoto não identificado
│ Localização: ...
└────────────────────────────────────────────────────────────
```

Uma tentativa falha **não significa que o servidor foi invadido**.

O importante é verificar se posteriormente houve:

```text
Accepted password
```

ou:

```text
Accepted publickey
```

para o mesmo IP.

---

## 📊 Resumo por IP

O relatório também agrupa os eventos:

```text
IP                   ACEITOS  FALHAS   ORIGEM
--------------------------------------------------------------------------
192.168.15.20        4        0        Rede local
100.x.x.x            2        0        Internet
203.0.113.42         0        15       Internet
```

Isso permite identificar rapidamente situações como:

```text
IP desconhecido
        ↓
muitas tentativas falhas
        ↓
Fail2ban bloqueou
```

ou uma situação mais preocupante:

```text
IP desconhecido
        ↓
tentativas falhas
        ↓
Accepted password/publickey
```

Nesse segundo caso, o acesso deve ser investigado imediatamente.

---

## 🛡️ Fail2ban

A quarta seção apresenta o estado da jail SSH:

```text
Status for the jail: sshd
|- Filter
|  |- Currently failed: 2
|  |- Total failed:     14
|  `- File list:        /var/log/auth.log
`- Actions
   |- Currently banned: 1
   |- Total banned:     3
   `- Banned IP list:   203.0.113.42
```

### Principais informações

| Campo            | Significado                               |
| ---------------- | ----------------------------------------- |
| Currently failed | Tentativas atualmente contabilizadas      |
| Total failed     | Total de falhas registradas pelo Fail2ban |
| Currently banned | IPs atualmente bloqueados                 |
| Total banned     | Total de IPs bloqueados                   |
| Banned IP list   | Lista dos IPs atualmente bloqueados       |

---

## ⚙️ Fonte dos logs

O script tenta utilizar automaticamente o `journalctl`.

Em sistemas que utilizam systemd:

```bash
journalctl -u ssh
```

ou:

```bash
journalctl -u sshd
```

Caso não esteja disponível, ele utiliza:

```text
/var/log/auth.log
```

Isso permite utilizar o script em diferentes versões do Ubuntu/Debian.

---

## 📦 Pré-requisitos

Sistema:

* Linux;
* Ubuntu ou Debian;
* OpenSSH Server;
* `sudo`.

Recomendado:

* Fail2ban;
* `curl`;
* `iproute2`.

### Instalar dependências

```bash
sudo apt update
sudo apt install openssh-server fail2ban curl iproute2 -y
```

---

## 🛡️ Instalação do Fail2ban

Caso ainda não esteja instalado:

```bash
sudo apt update
sudo apt install fail2ban -y
```

Ativar:

```bash
sudo systemctl enable --now fail2ban
```

Verificar:

```bash
sudo fail2ban-client status
```

E:

```bash
sudo fail2ban-client status sshd
```

---

## 📁 Estrutura

```text
.
├── check_ssh_security.sh
└── README.md
```

---

## ⏱️ Período analisado

Atualmente o script analisa:

```text
Últimas 48 horas
```

O período pode ser alterado diretamente no script:

```bash
HOURS=48
```

Por exemplo, para 24 horas:

```bash
HOURS=24
```

Ou para 7 dias:

```bash
HOURS=168
```

---

## 🔐 Interpretação rápida

### 🟢 Situação normal

```text
Logins aceitos:
192.168.15.20 → publickey

Falhas:
0
```

Provavelmente tudo normal.

### 🟡 Atenção

```text
Falhas:
203.0.113.42 → 20 tentativas
```

Pode ser um scanner ou bot tentando acessar o SSH.

Verifique o Fail2ban.

### 🔴 Situação crítica

```text
203.0.113.42
Falhas: 20

203.0.113.42
Accepted password
```

Um IP desconhecido que primeiro apresentou várias tentativas falhas e posteriormente conseguiu autenticar deve ser investigado imediatamente.

---

## 📅 Uso recomendado

Para uma verificação rápida:

```bash
sudo bash check_ssh_security.sh
```

Para facilitar a leitura:

```bash
sudo bash check_ssh_security.sh | less
```

Também é possível salvar o relatório:

```bash
sudo bash check_ssh_security.sh > relatorio_ssh.txt
```

E consultar posteriormente:

```bash
less relatorio_ssh.txt
```

---

## 🎯 Objetivo

O objetivo do script é fornecer uma visão rápida da atividade SSH recente do servidor, permitindo identificar:

* acessos legítimos;
* tentativas de invasão;
* IPs desconhecidos;
* autenticações por senha;
* autenticações por chave;
* dispositivos da rede local;
* possíveis origens geográficas;
* bloqueios realizados pelo Fail2ban.

O relatório deve ser utilizado como **ferramenta de monitoramento**, e não como prova definitiva da identidade ou localização de um dispositivo.
