Configuração do Volante Logitech G29 no Ubuntu Linux

Atualizado em: 17/07/2026
Ambiente alvo: Ubuntu 26.04 LTS

Este guia documenta o processo passo a passo para instalar e configurar o driver customizado de Force Feedback (new-lg4ff) e a interface gráfica de gerenciamento (oversteer) para volantes Logitech (G27, G29, G920) em sistemas baseados no Ubuntu.

🔗 Referências

Vídeo selecionado: https://www.youtube.com/watch?v=aTXz9ur7mOo

Vídeo Tutorial Base: Driver G27, G29, G920, e administração do Volante Oversteer - No Linux Mint

Repositório do Driver (new-lg4ff): https://github.com/berarma/new-lg4ff

Repositório da Interface (Oversteer): https://github.com/berarma/oversteer

🛠️ Passo 1: Preparando o Sistema e Dependências

Antes de começar, é importante garantir que o sistema está atualizado e possui todas as ferramentas de compilação necessárias (como o substituto atual do distutils, o setuptools).

# Atualize o sistema
sudo apt update && sudo apt upgrade

# Instale os pacotes de compilação (DKMS, Meson, Ninja) e dependências do Python
sudo apt install git dkms build-essential python3 python3-setuptools python3-gi python3-gi-cairo python3-pyudev python3-xdg python3-evdev gettext meson appstream-util desktop-file-utils python3-matplotlib python3-scipy


⚙️ Passo 2: Instalando o Driver do Kernel (new-lg4ff)

Este módulo substitui o driver padrão do kernel para habilitar os recursos avançados de Force Feedback. Utilizaremos o DKMS para que o módulo seja recompilado automaticamente caso o kernel do Ubuntu seja atualizado.

# 1. Clone o repositório do driver
git clone https://github.com/berarma/new-lg4ff.git

# 2. Copie o código para o diretório de fontes do sistema
sudo cp -R new-lg4ff/ /usr/src/

# 3. Verifique a versão do driver no arquivo de configuração
grep PACKAGE_VERSION /usr/src/new-lg4ff/dkms.conf
# Exemplo de saída: PACKAGE_VERSION="0.5.0"

# 4. Registre, compile e instale no DKMS (substitua 0.5.0 pela versão encontrada acima)
sudo dkms add -m new-lg4ff -v 0.5.0
sudo dkms build -m new-lg4ff -v 0.5.0
sudo dkms install -m new-lg4ff -v 0.5.0


Para verificar se o módulo foi assinado e instalado com sucesso, utilize:

modinfo hid_logitech


🎛️ Passo 3: Instalando a Interface Gráfica (Oversteer)

O Oversteer é o painel de controle onde configuramos os graus de rotação, testes de botões, LEDs e perfis de Force Feedback por jogo.

# 1. Clone o repositório do Oversteer
git clone https://github.com/berarma/oversteer.git
cd oversteer

# 2. Prepare o ambiente de compilação com o Meson
meson setup build

# 3. Entre na pasta gerada e compile o software
cd build
ninja

# 4. Instale o software no sistema
sudo ninja install


🚀 Passo 4: Pós-Instalação e Testes

Para garantir que o Linux aplique as permissões corretas assim que o volante for conectado via USB, recarregue as regras do gerenciador de dispositivos (udev):

sudo udevadm control --reload-rules
sudo udevadm trigger


Como testar:
Basta digitar oversteer no terminal ou procurar por "Oversteer" no menu de aplicativos do Ubuntu. Se o volante ainda não estiver conectado, a interface abrirá com a mensagem "No device available" (Comportamento esperado).

Quando conectar o G29, abra o Oversteer e configure seu perfil!