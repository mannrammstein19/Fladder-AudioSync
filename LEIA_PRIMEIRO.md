# Fladder com sincronização do áudio — pacote corrigido

Este pacote pequeno contém todas as alterações e a compilação para Windows no GitHub Actions. O workflow baixa automaticamente o código oficial Fladder 0.11.1 no commit fixado, aplica as alterações e compila. Não é necessário enviar o projeto completo nem instalar Flutter no seu PC.

## Gerar o aplicativo

1. Extraia este ZIP. Abra a pasta `Fladder-AudioSync`.
2. Crie um repositório na sua conta do GitHub. Pode ser privado, com Actions habilitado.
3. Envie o conteúdo desta pasta para a raiz do repositório, incluindo `.github`, `patch`, `LICENSE` e os documentos. NÃO envie a pasta `Fladder-AudioSync` como uma subpasta. O arquivo `.github/workflows/windows-audio-sync.yml` precisa estar na raiz do repositório.
4. Abra Actions → Compilar Fladder com ajuste de audio → Run workflow.
5. Aguarde o job Windows terminar com sucesso.
6. Baixe o artifact `Fladder-0.11.1-AudioSync-Windows`, extraia TODOS os arquivos e execute `fladder.exe` junto das DLLs e pastas extraídas.

O workflow não publica releases e não precisa da senha do Jellyfin. Se falhar, envie o nome da etapa e o texto do erro.

## Usar o ajuste

Mantenha MPV como reprodutor. Nas configurações do reprodutor ou nas opções durante um vídeo, use “Sincronização do áudio”. O botão “Testar -200 ms” é um ponto de partida para voz que chega depois do movimento dos lábios. Ajuste em passos de 50 ms e use “Zerar ajuste” quando trocar de saída de som.

O valor fica salvo neste dispositivo. Não há detecção automática do Frahm.

## Conteúdo e verificação

- `patch/`: 13 arquivos modificados, incluindo os modelos gerados e os testes.
- `.github/workflows/`: compilação manual que baixa o projeto oficial e aplica os arquivos de `patch/`.
- `VALIDACAO.md`: registro da análise sem problemas e dos quatro testes aprovados no ambiente Linux.
- `MANIFESTO.json`: hashes dos arquivos das alterações.
- `LICENSE`: licença original do projeto.

As alterações são as mesmas do pacote anterior; somente a embalagem foi reconstruída. O ZIP anterior estava incompleto.

Este arquivo é um kit para gerar o aplicativo, NÃO um instalador ou executável já compilado. A compilação Windows e o teste com o amplificador Frahm ainda estão pendentes.

Base oficial: https://github.com/DonutWare/Fladder — v0.11.1, commit a30343a30754114ca66fcae921a0949003761344.
Esta é uma modificação independente. Atualizações oficiais podem substituí-la.
