# Guia de Hardening e Manutenção para Servidor Linux (Home Lab)

Este repositório reúne diretrizes essenciais de administração de sistemas, comandos práticos e boas práticas de segurança aplicadas em um servidor Linux de laboratório doméstico. O foco principal é garantir alta disponibilidade, acesso remoto seguro e proteção contra vulnerabilidades comuns.

## Objetivo

Documentar procedimentos de manutenção, segurança e otimização para um ambiente Linux doméstico, com atenção especial a SSH, energia, logs, fail2ban e hardening.

## Sumário

- [Acesso remoto e segurança (SSH)](#1-acesso-remoto-e-segurança-ssh)
- [Gerenciamento de energia e CPU](#2-gerenciamento-de-energia-e-cpu)
- [Manutenção do sistema, logs e headless boot](#3-manutenção-do-sistema-logs-e-headless-boot)
- [Proteção ativa contra força bruta (Fail2ban)](#4-proteção-ativa-contra-força-bruta-fail2ban)
- [Análise de riscos e vetores de ataque](#5-análise-de-riscos-e-vetores-de-ataque-hardening)
- [Outros guias do repositório](#outros-guias-do-repositório)

## 1. Acesso remoto e segurança (SSH)

A administração remota deve ser feita exclusivamente via chaves criptográficas, como Ed25519, desativando o login direto por senha para reduzir o risco de ataques de força bruta.

### Gerar o par de chaves no dispositivo cliente

```bash
ssh-keygen -t ed25519
```

### Exibir a chave pública gerada

```bash
cat ~/.ssh/id_ed25519.pub
```

### Editar a lista de dispositivos autorizados no servidor

```bash
nano ~/.ssh/authorized_keys
```

### Reiniciar o serviço SSH após alterar configurações

```bash
sudo systemctl restart ssh
```

### Verificar o status da autenticação por senha no OpenSSH

```bash
sudo sshd -T | grep passwordauthentication
```

## 2. Gerenciamento de energia e CPU

Servidores rodando 24/7 exigem equilíbrio entre desempenho computacional e consumo elétrico. O uso de um perfil dinâmico permite reduzir o clock em repouso e responder rapidamente sob carga.

### Instalar utilitários de controle da CPU

```bash
sudo apt install linux-cpupower -y
```

### Verificar frequências e perfis ativos

```bash
cpupower frequency-info
```

### Definir perfil de economia máxima

```bash
sudo cpupower frequency-set -g powersave
```

### Definir perfil automático/dinâmico

```bash
sudo cpupower frequency-set -g ondemand
```

## 3. Manutenção do sistema, logs e headless boot

Servidores domésticos operam sem periféricos, o que torna essencial configurar o sistema operacional e a BIOS para ignorar a ausência de teclado ou monitor e evitar suspensões inesperadas.

### Ajustar o comportamento de suspensão do systemd

```bash
sudo nano /etc/systemd/logind.conf
```

Defina os parâmetros:

```text
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

### Reiniciar o gerenciador de sessões e login

```bash
sudo systemctl restart systemd-logind
```

### Monitorar logs do sistema em tempo real

```bash
journalctl -f
```

### Configuração da BIOS para headless boot

- Na aba Startup/Boot, defina Keyboardless Operation como Enabled (ou POST Error Handling como Disabled).
- Na aba Power, defina After Power Loss como Power On.

## 4. Proteção ativa contra força bruta (Fail2ban)

O Fail2ban monitora os logs de autenticação do sistema e bane temporariamente endereços IP que apresentem comportamentos suspeitos, como falhas consecutivas de login.

### Instalar o Fail2ban

```bash
sudo apt update && sudo apt install fail2ban -y
```

### Criar arquivo de configuração local

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

### Editar as regras do serviço

```bash
sudo nano /etc/fail2ban/jail.local
```

Na seção `[sshd]`, defina valores como:

```text
enabled = true
maxretry = 3 ou 5
bantime = 1h
```

### Reiniciar o serviço do Fail2ban

```bash
sudo systemctl restart fail2ban
```

### Verificar o status geral e as jails ativas

```bash
sudo fail2ban-client status
```

### Verificar IPs bloqueados na regra do SSH

```bash
sudo fail2ban-client status sshd
```

### Desbloquear manualmente um IP

```bash
sudo fail2ban-client unbanip <ENDEREÇO_IP>
```

## 5. Análise de riscos e vetores de ataque (Hardening)

Mesmo com redes sobrepostas criptografadas, como Tailscale, outras superfícies de ataque devem ser consideradas.

### 1. Dispositivos comprometidos e engenharia social

**Risco:** infecção por malware ou captura de credenciais em dispositivos clientes autorizados.

**Mitigação:**

- Manter os sistemas operacionais dos dispositivos clientes atualizados.
- Habilitar autenticação de dois fatores (2FA/MFA) nos provedores de identidade vinculados à VPN/Tailscale.
- Aplicar o princípio do menor privilégio, restringindo o acesso via SSH apenas a administradores da infraestrutura.

### 2. Vulnerabilidades na camada de aplicação (Docker / CasaOS)

**Risco:** exploração de falhas em serviços hospedados ou uso de credenciais padrão do fabricante.

**Mitigação:**

- Alterar todas as senhas padrão de administração imediatamente após a implantação de qualquer container.
- Atualizar regularmente as imagens do Docker e os pacotes do painel de gerenciamento.

### 3. Vetores na rede local (Wi-Fi / LAN)

**Risco:** dispositivos não autorizados conectados à rede local tentando varrer portas ou mover-se lateralmente.

**Mitigação:**

- Manter o Fail2ban ativo e escutando na interface de rede local.
- Utilizar criptografia forte no roteador (WPA2-AES ou WPA3).
- Isolar tráfego de visitantes em uma Guest Network sem acesso à sub-rede do servidor.

## Outros guias do repositório

- [README principal](../README.md)
- [Guia de SSH](../computador-estudos/README_HeardeningSSH.md)
- [Instalação e configuração do OpenSSH](../computador-estudos/README_OPENSSHinstalacao.md)
- [Segurança de servidor](../computador-estudos/README_SEGURANCASERVIDOR.md)
- [teste-sh](../computador-estudos/teste-sh)
