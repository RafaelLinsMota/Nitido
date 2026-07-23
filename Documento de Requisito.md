# Nítido — Documento de Requisitos e Plano de Desenvolvimento

**Versão:** 1.1
**Data:** 23 de julho de 2026
**Plataformas:** Android + iOS (Flutter)

---

## 1. Visão Geral do Produto

**Nítido** é um aplicativo de gerenciamento financeiro pessoal focado em três pilares: registrar renda, controlar contas a pagar (incluindo parceladas) e enxergar com clareza para onde o dinheiro está indo através de gráficos.

**Proposta de valor:** enquanto a maioria dos concorrentes trata parcelas e cartões como um detalhe secundário, o Nítido trata isso como cidadão de primeira classe — cada compra parcelada já nasce projetada nos meses seguintes, sem esforço manual do usuário.

**Diferencial competitivo:**
1. Design visual "Liquid Glass" — nenhum concorrente direto (Mobills, Organizze, LAPI, Minhas Economias) aposta em identidade visual diferenciada.
2. Tratamento de contas parceladas como recurso central, não um extra.
3. Simplicidade de escopo — o app faz bem o essencial antes de crescer para investimentos ou Open Finance.

---

## 2. Público-alvo

Pessoas que já têm alguma disciplina de anotar gastos (ou querem desenvolver esse hábito), recebem salário fixo ou variável, e têm contas mensais fixas e parceladas para acompanhar. Usuário confortável com apps mobile, sem necessidade de conhecimento financeiro avançado.

---

## 3. Escopo do MVP

O MVP cobre o ciclo completo de "recebi dinheiro → tenho contas a pagar → entendo pra onde foi meu dinheiro", sem funcionalidades de investimento, Open Finance ou compartilhamento familiar — essas ficam para fases seguintes.

---

## 4. Requisitos Funcionais (RF)

| ID | Descrição | Prioridade | Status |
|---|---|---|---|
| RF01 | Cadastro e login de usuário (e-mail/senha) | MVP | ✅ |
| RF02 | Cadastro de receitas (salário e outras entradas), com opção de recorrência mensal | MVP | ✅ |
| RF03 | Cadastro de contas a pagar com título, valor, categoria, vencimento e tipo (fixa / variável / parcelada) | MVP | ✅ |
| RF04 | Geração automática de lançamentos futuros para contas parceladas | MVP | ✅ |
| RF05 | Marcar conta como paga ou pendente | MVP | ✅ |
| RF06 | Editar e excluir lançamentos (receitas e contas) | MVP | ✅ |
| RF07 | Dashboard com saldo do mês, total de receitas, total de despesas e contas a vencer | MVP | ✅ |
| RF08 | Filtrar contas por mês e por status (todas / pendentes / pagas) | MVP | ✅ |
| RF09 | Gráfico de gasto por categoria (donut) | MVP | ✅ |
| RF10 | Gráfico de evolução mensal de gastos (barras, últimos 6 meses) | MVP | ✅ |
| RF11 | Ranking dos maiores gastos do mês | MVP | ✅ |
| RF12 | Notificação/lembrete de vencimento de contas | MVP | 🔜 |
| RF13 | Orçamento por categoria com alerta de limite | V2 | ✅ |
| RF14 | Metas de economia (ex: "Guardar R$ 5.000 pra viagem") | V2 | ✅ |
| RF15 | Exportar relatório (PDF/Excel) | V2 | ⏸️ Adiado (plugin Windows) |
| RF16 | Modo offline com cache local | V2 | 📋 A fazer |
| RF17 | Múltiplas contas/carteiras | V3 | ✅ |
| RF18 | Integração via Open Finance (importação automática de extrato) | V3 | 📋 A fazer |
| RF19 | Categorização automática de gastos via IA | V3 | 📋 A fazer |
| RF20 | Compartilhamento familiar de contas | V3 | 📋 A fazer |
| RF21 | Módulo de investimentos (integração com corretoras) | V3 | 📋 A fazer |

---

## 5. Requisitos Não Funcionais (RNF)

| ID | Descrição | Prioridade |
|---|---|---|
| RNF01 | App deve funcionar em Android e iOS a partir de uma única base de código (Flutter) | MVP |
| RNF02 | Interface deve seguir o design system "Liquid Glass" (glassmorphism, dark mode nativo) | MVP |
| RNF03 | Dashboard deve carregar em menos de 2s em conexão 4G | MVP |
| RNF04 | Dados sincronizados em nuvem, com autenticação segura (Supabase Auth + Row Level Security) | MVP |
| RNF05 | Respeitar preferências de acessibilidade (redução de movimento, contraste mínimo de texto, foco visível em botões) | MVP |
| RNF06 | Dados financeiros criptografados em trânsito e em repouso | MVP |
| RNF07 | Telas responsivas para diferentes tamanhos de tela (do iPhone SE ao tablet) | MVP |

---

## 6. Modelo de Dados

### `users`
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | identificador único |
| name | text | nome do usuário |
| email | text | e-mail (login) |
| created_at | timestamp | data de criação da conta |

### `incomes` (receitas)
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | identificador único |
| user_id | uuid (FK) | dono do lançamento |
| wallet_id | uuid (FK, nullable) | carteira vinculada |
| title | text | ex.: "Salário", "Freelance" |
| amount | numeric | valor |
| recurring | boolean | se repete todo mês |
| recurrence_day | int (nullable) | dia do mês em que recebe |
| received_at | date | data do recebimento |
| created_at | timestamp | |

### `categories`
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK, nullable) | nulo = categoria padrão do sistema |
| name | text | ex.: "Moradia", "Alimentação" |
| icon | text | referência ao ícone |
| color | text | hex color |

### `bills` (contas)
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK) | |
| wallet_id | uuid (FK, nullable) | carteira vinculada |
| category_id | uuid (FK) | |
| title | text | ex.: "Aluguel", "Cartão Nubank" |
| amount | numeric | valor da parcela/conta |
| type | enum | `fixa` \| `variavel` \| `parcelada` |
| due_date | date | vencimento |
| status | enum | `pendente` \| `paga` \| `atrasada` |
| installment_current | int (nullable) | parcela atual (ex.: 3) |
| installment_total | int (nullable) | total de parcelas (ex.: 12) |
| group_id | uuid (nullable) | agrupa parcelas da mesma compra |
| paid_at | date (nullable) | data em que foi paga |
| created_at | timestamp | |

### `wallets` (carteiras) — *Adicionado em 23/07/2026*
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | identificador único |
| user_id | uuid (FK) | dono da carteira |
| name | text | ex.: "Nubank", "Itaú", "Carteira" |
| type | enum | `conta_corrente` \| `poupanca` \| `carteira` \| `credito` |
| balance | numeric | saldo atual |
| color | text | hex color |
| icon | text | referência ao ícone |
| is_default | boolean | se é a carteira padrão |
| created_at | timestamp | |

### `budgets` (orçamentos) — *Adicionado em 23/07/2026*
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK) | |
| category_id | uuid (FK) | |
| amount | numeric | limite do orçamento |
| month | text | formato `YYYY-MM` |
| created_at | timestamp | |

### `savings_goals` (metas de economia) — *Adicionado em 23/07/2026*
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK) | |
| title | text | ex.: "Viagem pra praia" |
| target_amount | numeric | valor alvo |
| current_amount | numeric | quanto já guardou |
| deadline | date (nullable) | prazo opcional |
| icon | text | ícone |
| created_at | timestamp | |

> **Nota:** `group_id` é o que permite ao app gerar automaticamente as 12 linhas de uma compra parcelada em 12x e ainda saber que elas pertencem à mesma compra original.

---

## 7. Arquitetura e Stack Técnica

| Camada | Escolha | Justificativa |
|---|---|---|
| Frontend | Flutter (Dart) | código único Android/iOS, renderização própria — essencial pro visual glass ficar idêntico nas duas plataformas |
| Gerenciamento de estado | Riverpod | escala bem, testável, evita boilerplate do BLoC puro |
| Backend | Supabase (Postgres + Auth + RLS) | modelo relacional é mais natural pra parcelas/recorrência que NoSQL; auth pronto |
| Gráficos | fl_chart | maduro, customizável, mantém o visual glass |
| Notificações | flutter_local_notifications | lembretes de vencimento sem depender de servidor push no MVP |
| Exportação PDF | pdf (pacote Dart) | geração de relatórios |
| CI/CD | Codemagic ou GitHub Actions + Fastlane | build e deploy automatizado nas lojas |

---

## 8. Design System (resumo)

**Paleta**
- Fundo base: `#0A0714` (preto-ameixa profundo)
- Blobs ambientes: violeta `#6D28D9` + verde-água `#14B8A6`
- Texto primário: `#F5F3FF` · Texto secundário: `#A5A0C0`
- Positivo/receita: `#5EEAD4` (mint) · Negativo/despesa: `#FB7185` (coral) · Alerta/urgência: `#FBBF24` (âmbar)

**Tipografia**
- Manrope — números e headings
- Inter — corpo de texto e labels

**Componentes reutilizáveis**
`GlassCard` · `GlassBottomNav` · `GlassFAB` (com expansão Receita/Conta) · `StatCard` · `BillItem` (com swipe-to-pay) · `DonutChart` · `SegmentTab` · `CategoryIcon`

---

## 9. Telas do Produto

| Tela | Status | Descrição |
|---|---|---|
| Onboarding | 📋 A fazer | Introdução rápida ao app |
| Login/Cadastro | ✅ | Autenticação com biometria |
| Início (Dashboard) | ✅ | Saldo do mês, resumo receitas/despesas, orçamento por categoria, alertas, próximos vencimentos, seletor de carteira |
| Contas | ✅ | Lista de lançamentos com filtro (todas/pendentes/pagas), agrupamento por status, swipe-to-pay |
| Nova conta/receita | ✅ | Bottom sheet de cadastro com seleção de carteira |
| Gráficos | ✅ | Relatórios visuais: evolução mensal, donut por categoria, ranking de gastos |
| Orçamentos | ✅ | Cadastro de limite por categoria, alertas de ultrapassagem, reset mensal |
| Metas de Economia | ✅ | Criação de metas, depósito, acompanhamento de progresso |
| Carteiras | ✅ | Gerenciamento de múltiplas contas, saldo total, criar/editar/excluir |
| Perfil/Configurações | ✅ | Dados do usuário, categorias personalizadas, tema, exportar relatório |

---

## 10. Roadmap de Desenvolvimento

### Fase 1 — MVP ✅ Concluído
| Entregável | Status |
|---|---|
| Setup do projeto Flutter, integração Supabase | ✅ |
| Autenticação (email/senha + biometria) | ✅ |
| Design system "Liquid Glass" | ✅ |
| CRUD de receitas e contas | ✅ |
| Geração automática de parcelas | ✅ |
| Dashboard com saldo e alertas | ✅ |
| Tela de Contas com filtros | ✅ |
| Gráficos (donut, barras, ranking) | ✅ |
| Bottom sheet de cadastro | ✅ |

### Fase 2 — V2 ✅ Concluído
| Entregável | Status |
|---|---|
| Orçamento por categoria com alertas | ✅ |
| Metas de economia | ✅ |
| Exportação de relatórios PDF | ⏸️ Adiado (plugin Windows) |

### Fase 3 — V3 📋 Em andamento
| Entregável | Status |
|---|---|
| Múltiplas contas/carteiras | ✅ |
| Integração via Open Finance | 📋 A fazer |
| Categorização automática via IA | 📋 A fazer |
| Compartilhamento familiar | 📋 A fazer |
| Módulo de investimentos | 📋 A fazer |

### Fase 4 — Extras
| Entregável | Status |
|---|---|
| Modo offline com cache local | 📋 A fazer |
| Notificações de vencimento | 📋 A fazer |
| Onboarding introdutório | 📋 A fazer |

---

## 11. Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Mercado competitivo e saturado (Mobills, Organizze, LAPI, Minhas Economias) | Diferenciação por design e por tratamento de parcelas como recurso central |
| Apps financeiros têm alto abandono nas primeiras semanas de uso | Onboarding simples, valor percebido imediato no dashboard, notificações úteis e não invasivas |
| Complexidade de Open Finance/investimentos | Adiado para V3; MVP focado em lançamento manual, que já entrega valor |
| Performance do efeito glass (blur) em Android de entrada | Testar em dispositivos de gama baixa; ter fallback com blur reduzido se necessário |

---

## 12. Análise Competitiva (resumo)

| App | Posicionamento | Nosso diferencial |
|---|---|---|
| Mobills | Líder de mercado, multiplataforma, freemium | Design mais moderno, foco maior em parcelas |
| Organizze | Simples, controle manual tradicional | Visual mais atual, gráficos mais ricos |
| LAPI | Multiplataforma, cartão agrupado por fatura, IA coach | Mesma força em parcelas, com identidade visual própria |
| Meu Dinheiro | Controle + investimentos integrados | Escopo mais enxuto no MVP, investimento fica pra V3 |
| Jota | Automação via WhatsApp + Open Finance | Nítido é um app tradicional, não um assistente conversacional |

---

## 13. Métricas sugeridas para acompanhar no MVP

- % de usuários que cadastram ao menos 1 receita e 3 contas na primeira semana
- Retenção em D7 e D30
- % de contas parceladas cadastradas vs. contas simples (valida o diferencial central)
- Tempo médio até o primeiro lançamento após o cadastro

*(Definir metas numéricas específicas exige dados de baseline — recomenda-se estabelecê-las após as primeiras semanas de uso real.)*

---

## 14. Changelog

### 23/07/2026

**Novas funcionalidades:**
- **Múltiplas contas/carteiras** (RF17)
  - Modelo `Wallet` com tipos: conta corrente, poupança, carteira, cartão de crédito
  - Tela de gerenciamento de carteiras com cores, ícones e seleção
  - Seletor de carteira no dashboard (home) e ao criar receita/despesa
  - Provider `selectedWalletProvider` para filtrar dados por carteira
  - Migration SQL com RLS e trigger de carteira padrão única

**Correções:**
- Removido `share_plus` e `path_provider` (problemas com symlinks no Windows)
- Exportação de PDF agora usa `Process.run` para abrir o arquivo diretamente no Windows
- Corrigido clipping do `GlassCard` que cortava conteúdo dos filhos
- Corrigido `StatCard` com `maxLines: 1` e `overflow: TextOverflow.ellipsis`

**Técnicos:**
- Adicionado campo `wallet_id` em `bills` e `incomes` (models + services + providers)
- Navigation atualizada para 7 abas: Home, Contas, Gráficos, Carteiras, Orçamentos, Metas, Perfil
- `WalletsService` com CRUD + `getTotalBalanceSync` + `getWalletSummary`

### 22/07/2026

**Novas funcionalidades:**
- **Orçamento por categoria** (RF13)
  - Modelo `Budget` com mês como String (`YYYY-MM`)
  - Serviço `BudgetsService` com CRUD, `getCategorySpending`, `resetMonth`
  - Tela `BudgetsScreen` com categorias fallback, seletor de mês, barras de progresso
  - Alertas de orçamento no dashboard

- **Metas de economia** (RF14)
  - Modelo `SavingsGoal` com progresso e dias restantes
  - Serviço `SavingsService` com CRUD + depósito (cria registro de despesa)
  - Tela `SavingsGoalsScreen` com progresso individual e total

**Correções:**
- Corrigido `GlassCard` — reestruturado para não cortar conteúdo dos filhos
- Corrigido `DropdownButtonFormField` — substituído por `DropdownButton` + `Consumer`

**Técnicos:**
- RLS policies para `budgets` e `savings_goals`
- Botão "Zerar Mês" em orçamentos
- Dependências: `pdf`, `path_provider`, `share_plus` (depois removidos)
