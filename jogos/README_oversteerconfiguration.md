# Configuração do Volante Logitech G29 no Ubuntu Linux

**Atualizado em:** 17/07/2026  
**Ambiente alvo:** Ubuntu 26.04 LTS

Este guia documenta o processo passo a passo para instalar e configurar o driver customizado de Force Feedback (new-lg4ff) e a interface gráfica de gerenciamento (Oversteer) para volantes Logitech (G27, G29, G920) em sistemas baseados no Ubuntu.

## ⚠️ Aviso crítico de hardware (leia antes de começar)

Para que o Linux e este driver reconheçam o seu volante corretamente, você DEVE mudar a chave seletora na parte superior do Logitech G29 para a posição **PS3**.

Se a chave estiver no modo **PS4**, o volante enviará um ID USB criptografado (focado no console da Sony) que fará o driver falhar e não reconhecer o dispositivo. No modo PS3, ele se comporta como um periférico de PC padrão.

## 🔗 Referências

- Vídeo Tutorial Base: Driver G27, G29, G920, e administração do Volante Oversteer - No Linux Mint
- Repositório do Driver (new-lg4ff): https://github.com/berarma/new-lg4ff
- Repositório da Interface (Oversteer): https://github.com/berarma/oversteer

## 🛠️ Passo 1: Preparando o Sistema e Dependências

Antes de começar, é importante garantir que o sistema está atualizado e possui todas as ferramentas de compilação necessárias.

```bash
sudo apt update && sudo apt upgrade
```

Instale os pacotes de compilação (DKMS, Meson, Ninja) e dependências do Python:

```bash
sudo apt install git dkms build-essential python3 python3-setuptools python3-gi python3-gi-cairo python3-pyudev python3-xdg python3-evdev gettext meson appstream-util desktop-file-utils python3-matplotlib python3-scipy
```

## ⚙️ Passo 2: Instalando o Driver do Kernel (new-lg4ff)

Este módulo substitui o driver padrão do kernel para habilitar os recursos avançados de Force Feedback. Utilizaremos o DKMS para que o módulo seja recompilado automaticamente caso o kernel do Ubuntu seja atualizado.

```bash
git clone https://github.com/berarma/new-lg4ff.git
sudo cp -R new-lg4ff/ /usr/src/
grep PACKAGE_VERSION /usr/src/new-lg4ff/dkms.conf
```

Exemplo de saída:

```text
PACKAGE_VERSION="0.5.0"
```

Substitua `0.5.0` pela versão encontrada no arquivo de configuração e execute:

```bash
sudo dkms add -m new-lg4ff -v 0.5.0
sudo dkms build -m new-lg4ff -v 0.5.0
sudo dkms install -m new-lg4ff -v 0.5.0
```

Para verificar se o módulo foi assinado e instalado com sucesso, utilize:

```bash
modinfo hid_logitech
```

## 🎛️ Passo 3: Instalando a Interface Gráfica (Oversteer)

O Oversteer é o painel de controle onde configuramos os graus de rotação, testes de botões, LEDs e perfis de Force Feedback por jogo.

```bash
git clone https://github.com/berarma/oversteer.git
cd oversteer
meson setup build
cd build
ninja
sudo ninja install
```

## 🚀 Passo 4: Pós-Instalação e Testes

Para garantir que o Linux aplique as permissões corretas assim que o volante for conectado via USB, recarregue as regras do udev:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Como testar:

- Digite `oversteer` no terminal ou procure por "Oversteer" no menu de aplicativos do Ubuntu.
- Se o volante ainda não estiver conectado, a interface abrirá com a mensagem "No device available" (comportamento esperado).
- Quando conectar o G29, confirme se a chave física está em **PS3**, abra o Oversteer e configure seu perfil de Force Feedback e rotação.
