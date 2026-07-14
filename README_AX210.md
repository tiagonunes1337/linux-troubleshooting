# Linux Troubleshooting: Intel AX210 Wi-Fi Initialization Issues

## O Problema
Em setups de **Dual Boot** (Windows + Linux), a placa de rede Intel AX210 Wi-Fi 6E ou outras placas de rede muitas vezes não é reconhecida ou para de funcionar no Linux, ficando com o ícone de rede ausente, como se o hardware não estivesse instalado.  

## A Causa Raiz
O recurso **"Fast Startup" (Inicialização Rápida)** do Windows é o principal responsável por esse comportamento. Quando ativado, o Windows não desliga completamente o hardware, colocando os componentes em um estado de hibernação profunda (`D3 state`) para acelerar o próximo boot. Isso deixa a placa Wi-Fi em um estado de "travamento" elétrico que o kernel do Linux (driver `iwlwifi`) não consegue inicializar corretamente.  

## A Solução

### 1. Desativar a Inicialização Rápida no Windows
Para evitar que o Windows bloqueie o hardware ao ser encerrado:

1. Vá ao **Painel de Controle** > **Hardware e Sons** > **Opções de Energia**.
2. Clique em **"Escolher a função dos botões de energia"**.
3. Selecione **"Alterar configurações não disponíveis no momento"** (requer privilégios de administrador).
4. **Desmarque** a opção "Ligar inicialização rápida (recomendado)".
5. Salve as alterações.

### 2. Atualização dos Drivers da Placa da INTEL(Ou outra fabricante) 

1. Vá ao **Site da Fabricante ou Intel** > **Se for intel acessa o site oficial da Intel de acordo com a sua Placa**
2. Atualiza a Placa de Rede, Wifi e Bluetooth(Se tiver)
3. Depois do processo feito, Reiniciaremos a maquina

### 3. Ciclo de Energia (Cold Boot)
Se o problema persistir após desativar o recurso, realize um *Cold Boot* para limpar o estado de energia residual da placa-mãe:

1. Desligue o PC completamente pelo sistema.
2. Remova o cabo de força.
3. Mantenha o botão **Power** pressionado por 15 a 20 segundos para drenar a energia dos capacitores.
4. Espera 2 minutos completamente mesmo tendo apertado o botão
5. Reconecte o cabo e ligue o computador.

## Verificação
Após iniciar o Linux, verifique se o driver `iwlwifi` carregou corretamente utilizando o comando:

```bash
lspci -k | grep -A 3 -i network
```

O resultado deve confirmar que o driver está em uso, validando o sucesso da inicialização.  

*Log técnico desenvolvido como parte do meu portfólio de Engenharia de Software, documentando a resolução de problemas de hardware e sistemas operacionais.*
