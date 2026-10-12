# Fladder 0.11.1 — Trailers locais e música tema

Atualização incremental para o seu repositório Fladder-AudioSync, baseada no commit ac72302d287d5a4c09c93c99133fe34b8194a489. Não apague os arquivos antigos de patch: eles mantêm o AudioSync e o botão da barra do player.

## Instalar pelo GitHub
1. Extraia este ZIP.
2. Na raiz do seu repositório Fladder-AudioSync, abra Add file > Upload files e arraste a pasta patch inteira. Confirme em Commit changes.
3. Atualize .github/workflows/main.yml com o arquivo do mesmo caminho incluído aqui. Você pode arrastar a pasta .github inteira para Upload files na raiz. Se preferir, abra Code > .github > workflows > main.yml > lápis e substitua TODO o conteúdo pelo deste arquivo.
4. Em Actions, selecione Compilar Fladder com trailers e temas > Run workflow > main.
5. Somente após o resultado verde, baixe o artifact Fladder-0.11.1-Extras-Windows. Extraia TODOS os arquivos em uma pasta nova e abra fladder.exe.

## Funcionamento
- No detalhe do filme ou da série, ao lado das ações, aparece Trailer quando o Jellyfin fornece arquivos locais.
- Com um trailer, o botão reproduz diretamente no player existente, desde o começo.
- Com vários, abre Escolher trailer e permite selecionar um dos nomes fornecidos pelo Jellyfin. Fechar essa lista não inicia reprodução.
- Séries com músicas tema reconhecidas pelo Jellyfin ganham Música tema e um botão de volume separado.
- Tema automático ativado inicialmente; volume inicial de 20%. A escolha e o volume ficam salvos no aparelho e são compartilhados entre as páginas.
- A música é pausada se o detalhe deixa de ser a página atual, se o aplicativo perde o primeiro plano, ou se o player principal está aberto (inclusive minimizado/pausado).
- Ao fechar o detalhe, o player de tema é descartado. Após voltar do player, o tema pode retomar se a página estiver ativa.
- Se a série tiver várias músicas tema, esta primeira versão usa a primeira devolvida pelo servidor, em repetição.
- Falhas de consulta mostram botões para tentar novamente. Sem trailers ou temas locais, os respectivos botões não aparecem.

## Verificação e limites
A lógica do controlador de áudio foi testada localmente em Dart: URL com subpasta do servidor, condições de reprodução, cancelamento de intenção durante carregamento, descarte, volume e reabertura após erro. Os arquivos Dart passaram pelo parser/formatador, as traduções JSON são válidas e git diff --check não encontrou erros.

A instalação local das dependências foi bloqueada pela revisão automática porque tentou acessar o endpoint de metadados da máquina. Não foi contornado esse bloqueio. Portanto, análise completa, 8 testes novos da interface/lógica, testes de AudioSync e compilação Windows ainda estão PENDENTES no GitHub Actions. Este pacote contém código para compilar, não um executável já testado. Ainda falta conferir a reprodução no seu servidor e no seu PC.

A autenticação do tema é enviada em cabeçalho ao servidor configurado. Nenhum plugin, download de trailer ou alteração da biblioteca Jellyfin é necessário para usar os arquivos já reconhecidos.
