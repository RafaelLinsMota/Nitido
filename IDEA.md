Contexto: Nítido é um app de finanças pessoais em Flutter, backend Supabase 
(PostgreSQL), gerenciamento de estado com Riverpod. Projeto em C:\Projetos\Nitido.

Arquivos relevantes para esta tarefa:
- lib\core\services\bills_service.dart (serviço de contas: criar/atualizar/excluir)
- lib\features\home\home_screen.dart (contém o NewEntrySheet, onde contas e 
  receitas são cadastradas)
- lib\features\bills\bills_screen.dart (tela de listagem de contas)
- Documento de Requisito.md (lista completa de requisitos do app)

Tarefa (RF04 - Alta Prioridade, MVP):
Implementar a geração automática de lançamentos futuros para contas parceladas. 
Quando o usuário cadastra uma conta como parcelada (ex: 12x de R$100), o sistema 
deve gerar automaticamente as parcelas futuras correspondentes, com datas de 
vencimento corretas (mensal, a partir da data da primeira parcela), vinculadas 
à mesma compra original, para aparecerem certo na tela de Contas e nos gráficos.

Antes de implementar, por favor:
1. Inspecione o schema atual da tabela de contas no Supabase (e os models Dart 
   em bills_service.dart) pra ver se já existem campos como numero_parcela, 
   total_parcelas ou um id que agrupe parcelas da mesma compra.
2. Verifique se o NewEntrySheet (home_screen.dart) já captura número de parcelas 
   no cadastro — se não, será preciso adicionar esse campo na UI também.
3. Proponha e implemente a abordagem (ex: inserir N registros no Supabase ao 
   salvar uma conta parcelada, cada um com data de vencimento e número da 
   parcela), mantendo o padrão de código já usado no projeto (Riverpod, upsert).
4. Ao final, rode os testes existentes (test/widget_test.dart) e confirme que 
   nada quebrou.

Comece analisando o código atual antes de implementar.
