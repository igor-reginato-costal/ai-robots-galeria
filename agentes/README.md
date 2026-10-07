# Central de agentes COSTAL

Página independente em `https://ai-robots-galeria.netlify.app/agentes/`. O Portal deve apenas apontar para a central por um link. Não incorporar esta entrega na página principal do Portal. O site público não exige bibliotecas ou build.

## Fonte única

Nomes, imagens, edições, funções e descrições são lidos do bloco JSON `#agent-data` de `../index.html`, que é gerado pelo fluxo original da galeria. A aplicação usa DOMParser e JSON.parse; não executa HTML ou scripts importados.

`registro.json` guarda somente os dados complementares: ID, área, situação, responsáveis públicos, acesso, documentação e guias. O campo `additionalAgents` permite incluir agentes confirmados ainda ausentes da galeria. Quando forem incorporados à galeria, migrar o complemento para `agents` para evitar duplicidade. A chave de correspondência atual é o nome; preservar o ID se houver renomeação e atualizar a chave explicitamente.

## Situação R01 · 07/10/2026

- 55 funções catalogadas a partir da galeria.
- 68 mascotes de reserva continuam somente na galeria original.
- 16 agentes nativos e 5 GPTs legados tiveram configurações consultadas na conta indicada pelo responsável.
- 7 correspondências com a galeria e 14 registros adicionais: 69 registros no catálogo.
- 25 guias: 21 baseados em configurações e 4 conceituais (PLAY, RELAY, VOICE e MENTOR).
- Dois rascunhos preservados fora da contagem. Dra legado mantido separado de Legal – Dra, com revisão de escopo pendente.
- Nenhum acesso da equipe ou teste funcional de agente foi validado nesta edição. Configuração presente não prova execução.
- Configurações completas e instruções internas permanecem em dossiê local, fora deste repositório público.
- Exemplos e roteiros são propostas didáticas; não são resultados de execução dos agentes.

Não preencher desconhecidos por inferência. A liberação do botão de acesso exige `status: "Disponível"`, `accessVerified: true` e URL HTTPS válida.

## Atualização

1. Levantar a implementação real e preencher o modelo de documentação em local autorizado.
2. Conferir nome e aliases; evitar duplicidade entre GPT, mascote e automação.
3. Atualizar somente informações próprias para publicação em `registro.json`.
4. Registrar evidência de testes em ambiente restrito e versão/data/responsável no registro público.
5. Verificar filtros, diálogos, links, teclado e celular.
6. Publicar pelo fluxo GitHub → Netlify existente e conferir a página independente.

O diretório é público: não armazenar credenciais, configurações privadas, base de conhecimento interna ou documentos restritos. Campo oculto no JSON continua público.

## Verificação local

Servir a raiz do repositório por HTTP e abrir `/agentes/`. O cadastro original precisa estar presente em `index.html`. Imagens usam os caminhos da fonte; em checkout esparso, podem faltar localmente, mas permanecem no deploy completo do repositório.

Testar busca sem acentos, filtros combinados, estado vazio, paginação, guias, ficha técnica, Escape, foco, teclado nas abas, exportação CSV e Markdown, carregamento sob demanda da galeria, aparência clara/escura e movimento reduzido.

## Próximas evidências necessárias

Responsáveis formais; acesso pelos destinatários; conteúdo e vigência das fontes; operação das integrações; habilidades recolhidas no editor; testes funcionais de cada implementação. O inventário cobre somente o ambiente visível na sessão consultada, sem afirmar cobertura de outras contas ou workspaces. Verificar o aviso de migração apresentado pelo editor dos GPTs legados antes de planejar sua continuidade.
