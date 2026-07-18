# Linux Troubleshooting: Intel AX210 Wi-Fi Initialization Issues

Este guia foi organizado com foco em ambientes Ubuntu, especialmente versões baseadas em Ubuntu 24.04 LTS, para ajudar na resolução de problemas de inicialização da placa Wi-Fi Intel AX210 em sistemas com dual boot.

## O Problema
Em setups de dual boot com Windows e Linux, a placa Intel AX210 Wi-Fi 6E ou outras placas semelhantes podem não ser reconhecidas corretamente no Linux. O resultado costuma ser um ícone de rede ausente, como se o hardware não estivesse instalado.

## Causa Raiz
O principal vilão costuma ser o recurso de inicialização rápida do Windows, conhecido como Fast Startup. Quando ele está ativo, o Windows não encerra completamente o hardware, deixando componentes em um estado semelhante a hibernação profunda. Isso pode travar a placa Wi-Fi em um estado que o kernel Linux, por meio do driver `iwlwifi`, não consegue restaurar corretamente.

A solução não veio de um truque isolado, mas de uma combinação de investigação técnica, testes e ajustes práticos. Em muitos casos, o problema só foi resolvido após revisar informações de fontes técnicas, incluir referências encontradas em comunidades como Reddit e complementar a análise com apoio de ferramentas de IA, como o Gemini e Claude, para validar hipóteses e consolidar um caminho de correção.

## Solução

### 1. Desativar a Inicialização Rápida no Windows
Para evitar que o Windows trave o hardware ao ser desligado:

1. Acesse o Painel de Controle > Hardware e Sons > Opções de Energia.
2. Clique em "Escolher a função dos botões de energia".
3. Selecione "Alterar configurações não disponíveis no momento" (é necessário privilégios de administrador).
4. Desmarque a opção "Ligar inicialização rápida (recomendado)".
5. Salve as alterações.

### 2. Atualizar os Drivers da Placa
1. Acesse o site oficial da fabricante (por exemplo, Intel) e baixe os drivers mais recentes para rede, Wi-Fi e Bluetooth.
2. Instale os drivers no Windows.
3. Reinicie o computador.

### 3. Realizar um Cold Boot
Se o problema persistir, faça um ciclo completo de energia para limpar o estado residual da placa-mãe:

1. Desligue o computador completamente.
2. Desconecte o cabo de força da tomada.
3. Pressione e segure o botão Power por 15 a 20 segundos.
4. Aguarde cerca de 2 minutos.
5. Reconecte o cabo e ligue novamente.

---

## Soluções Avançadas e Automação

### 4. Configuração de Energia na BIOS
Em algumas placas-mãe, especialmente modelos ASRock, a energia pode permanecer ligada em periféricos mesmo após o desligamento. Isso pode manter a placa Wi-Fi em um estado bloqueado.

1. Reinicie o computador e entre na BIOS (geralmente com `F2` ou `Del`).
2. Acesse a seção Advanced > ACPI Configuration.
3. Ajuste as opções abaixo, se disponíveis:
   - **Deep Sleep**: habilite **Enabled in S4&S5**.
   - **Lan Devices Power On / Wake-on-LAN**: desative.
4. Salve as mudanças com `F10` e reinicie.

### 5. Desbloqueio Automático no Linux com systemd
Se o sistema continuar aplicando um bloqueio suave no adaptador Wi-Fi durante o boot, você pode criar um serviço para desbloqueá-lo automaticamente.

1. Crie o arquivo do serviço:

```bash
sudo nano /etc/systemd/system/wifi-unblock.service
```

2. Cole o conteúdo abaixo:

```ini
[Unit]
Description=Unblock WiFi at startup
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/rfkill unblock wifi

[Install]
WantedBy=multi-user.target
```

3. Salve e saia do editor (`Ctrl+O`, `Enter`, `Ctrl+X`).

4. Habilite o serviço:

```bash
sudo systemctl daemon-reload
sudo systemctl enable wifi-unblock.service
```

## Verificação Final
Após reiniciar o Linux, confirme se o driver `iwlwifi` foi carregado corretamente:

```bash
lspci -k | grep -A 3 -i network
```

Para validar se o desbloqueio do `rfkill` funcionou, use:

```bash
rfkill list
```

O adaptador não deve aparecer com a opção "Soft blocked: yes".

---

Log técnico desenvolvido como parte do portfólio de Engenharia de Software, documentando a resolução de problemas de hardware e sistemas operacionais.