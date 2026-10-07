# Central de agentes COSTAL

Página estática em `/agentes/`, incorporável no Google Sites. O site público não exige bibliotecas ou build.

## Fonte única

Nomes, imagens, edições, funções e descrições são lidos do bloco JSON `#agent-data` de `../index.html`, que é gerado pelo fluxo original da galeria. A aplicação usa DOMParser e JSON.parse; não executa HTML ou scripts importados.

`registro.json` guarda somente os dados complementares: ID, área, situação, responsáveis públicos, acesso, documentação e guias. O campo `additionalAgents` permite incluir agentes confirmados ainda ausentes da galeria. Quando forem incorporados à galeria, migrar o complemento para `agents` para evitar duplicidade. A chave de correspondência atual é o nome; preservar o ID se houver renomeação e atualizar a chave explicitamente.

## Situação inicial

- 55 funções catalogadas a partir da galeria.
- 68 mascotes de reserva continuam somente na galeria original.
- 5 guias preliminares: PLAY, KNOW, RELAY, VOICE e MENTOR.
- Nenhuma implementação, configuração privada ou permissão de GPT foi verificada nesta edição.
- Exemplos e roteiros são propostas didáticas; não são resultados de execução dos agentes.

Não preencher desconhecidos por inferência. A liberação do botão de acesso exige `status: "Disponível"`, `accessVerified: true` e URL HTTPS válida.

## Atualização

1. Levantar a implementação real e preencher o modelo de documentação em local autorizado.
2. Conferir nome e aliases; evitar duplicidade entre GPT, mascote e automação.
3. Atualizar somente informações próprias para publicação em `registro.json`.
4. Registrar evidência de testes em ambiente restrito e versão/data/responsável no registro público.
5. Verificar filtros, diálogos, links, teclado e celular.
6. Publicar pelo fluxo GitHub → Netlify existente e conferir o Portal.

O diretório é público: não armazenar credenciais, configurações privadas, base de conhecimento interna ou documentos restritos. Campo oculto no JSON continua público.

## Verificação local

Servir a raiz do repositório por HTTP e abrir `/agentes/`. O cadastro original precisa estar presente em `index.html`. Imagens usam os caminhos da fonte; em checkout esparso, podem faltar localmente, mas permanecem no deploy completo do repositório.

Testar busca sem acentos, filtros combinados, estado vazio, paginação, guias, ficha técnica, Escape, foco, teclado nas abas, exportação CSV e Markdown, carregamento sob demanda da galeria, aparência clara/escura e movimento reduzido.

## Próximas evidências necessárias

Inventário de Meus GPTs na conta pessoal informada pelo proprietário; correspondência com as 55 funções; responsáveis; acesso por destinatário; configuração, conhecimento, ferramentas, integrações; testes de cada implementação. Não declarar o levantamento completo até concluir esses itens.
