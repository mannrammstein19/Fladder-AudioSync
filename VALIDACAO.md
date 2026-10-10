# Validação desta alteração

Base: Fladder v0.11.1, commit a30343a30754114ca66fcae921a0949003761344.
Ambiente de verificação: Linux, Flutter 3.35.7 e Dart 3.9.2.

## Concluído

- Dependências obtidas com `flutter pub get --enforce-lockfile`, preservando `pubspec.lock`.
- Modelos Freezed/JSON do reprodutor regenerados com build_runner.
- Traduções geradas com `flutter gen-l10n`.
- `dart analyze --no-fatal-warnings` nos sete arquivos de implementação modificados: **No issues found!**
- `flutter test test/audio_sync_test.dart`: **4 testes passaram**.
  - Configurações antigas continuam com atraso zero.
  - Valores positivos e negativos sobrevivem à gravação/leitura JSON, mantendo MPV selecionado.
  - A mudança do atraso altera o estado sem solicitar recriação do player.
  - Botão -200 ms, controle de valores negativos e botão de reset funcionam.
- Arquivos de tradução JSON e os dois workflows YAML verificados.
- `git diff --check`: sem erros de espaços/conflitos.
- Confirmada no código da dependência a API `NativePlayer.setProperty(String, String)`.
- Alterações nos modelos gerados de outros módulos durante build_runner foram descartadas para preservar o escopo.

## Pendente

- A compilação Windows não foi executada neste ambiente Linux.
- O executável não foi iniciado em um PC Windows.
- Não houve teste de áudio com Bluetooth, TP-Link UB500 ou amplificador Frahm.
- O valor -200 ms é um ponto de partida, não uma medição da latência do seu equipamento.

Os workflows incluídos repetem a análise e os quatro testes no Windows antes de compilar.
O teste final exige gerar o artifact e conferir a reprodução no seu equipamento.
