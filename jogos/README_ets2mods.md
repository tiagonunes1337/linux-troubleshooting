# Guia: Instalação de Mods no ETS2 via Proton (Linux)

Este documento detalha como gerenciar mods para o Euro Truck Simulator 2 (ETS2) quando executado via Proton no Linux. Diferente da versão nativa, a versão Proton utiliza um ambiente de compatibilidade (prefixo) que isola os arquivos de configuração do jogo.

---

## O Desafio: Prefixo do Proton
Ao rodar jogos via Proton, a Steam cria um ambiente virtual (equivalente a uma pasta `C:` do Windows). Por isso, a pasta de documentos do jogo não fica na `home` do Linux, mas dentro da pasta de instalação da biblioteca Steam.

## Localizando a Pasta de Mods
Para encontrar onde colocar seus arquivos `.scs`, siga este caminho dentro do seu diretório Steam:

`[Caminho-do-Seu-Disco]/SteamLibrary/steamapps/compatdata/227300/pfx/drive_c/users/steamuser/Documents/Euro Truck Simulator 2/mod`

*Nota: O ID `227300` é específico para o Euro Truck Simulator 2.*

## Passo a Passo para Instalação
1.  **Navegue até o caminho indicado acima.**
2.  **Verifique a existência da pasta `mod`**: Se ela não existir, crie-a manualmente (`mkdir mod`).
3.  **Adicione aos Favoritos**: No seu gerenciador de arquivos, clique com o botão direito na pasta `Euro Truck Simulator 2` (ou na pasta `mod`) e selecione "Adicionar aos Favoritos". Isso economizará muito tempo futuramente.
4.  **Copie os arquivos**: Cole seus arquivos de mod (`.scs`) dentro dessa pasta.
5.  **Ative no Jogo**: Abra o ETS2, vá ao **Mod Manager** e ative os mods desejados.

## Dica Importante
*   **Isolamento**: Mods instalados na versão Nativa Linux do ETS2 **não** aparecem na versão Proton. Se você migrar entre as versões, precisará copiar os arquivos manualmente para a pasta correspondente de cada uma.