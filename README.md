# Nítido

**Suas finanças em foco**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.5+-3FCF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Visão Geral

**Nítido** é um aplicativo de gerenciamento financeiro pessoal focado em três pilares: registrar renda, controlar contas a pagar (incluindo parceladas) e enxergar com clareza para onde o dinheiro está indo através de gráficos.

### Diferencial Competitivo
1. **Design "Liquid Glass"** — glassmorphism escuro com blobs ambientes violeta + verde-água
2. **Parcelas como cidadão de primeira classe** — compras parceladas já nascem projetadas nos meses seguintes
3. **Simplicidade de escopo** — faz bem o essencial antes de crescer

---

## Stack Técnica

| Camada | Tecnologia | Justificativa |
|---|---|---|
| Frontend | Flutter (Dart) | Código único Android/iOS, renderização própria para o visual glass |
| Estado | Riverpod | Escala bem, testável, sem boilerplate |
| Backend | Supabase (Postgres + Auth + RLS) | Modelo relacional natural para parcelas/recorrência |
| Gráficos | fl_chart | Maduro, customizável |
| Notificações | flutter_local_notifications | Lembretes sem servidor push no MVP |
| CI/CD | GitHub Actions + Fastlane | Build automatizado |

---

## Paleta de Cores

| Elemento | Cor | Código |
|---|---|---|
| Fundo base | Preto-ameixa | `#0A0714` |
| Blobs ambientes | Violeta | `#6D28D9` |
| Blobs ambientes | Verde-água | `#14B8A6` |
| Texto primário | Branco suave | `#F5F3FF` |
| Texto secundário | Lilás muted | `#A5A0C0` |
| Receita/positivo | Mint | `#5EEAD4` |
| Despesa/negativo | Coral | `#FB7185` |
| Alerta | Âmbar | `#FBBF24` |

## Tipografia

- **Manrope** — números e headings (pesos 500–800)
- **Inter** — corpo de texto e labels (pesos 400–600)

---

## Modelo de Dados

### `users`
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | Referência ao auth.users |
| name | text | Nome do usuário |
| email | text | E-mail (login) |
| created_at | timestamp | Data de criação |

### `incomes`
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | Identificador único |
| user_id | uuid (FK) | Dono do lançamento |
| title | text | Ex.: "Salário", "Freelance" |
| amount | numeric | Valor |
| recurring | boolean | Se repete todo mês |
| recurrence_day | int | Dia do mês |
| received_at | date | Data do recebimento |
| created_at | timestamp | |

### `categories`
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK, nullable) | Nulo = categoria do sistema |
| name | text | Ex.: "Moradia" |
| icon | text | Referência ao ícone |
| color | text | Hex color |

### `bills`
| Campo | Tipo | Descrição |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK) | |
| category_id | uuid (FK) | |
| title | text | Ex.: "Aluguel" |
| amount | numeric | Valor da parcela/conta |
| type | enum | `fixa` \| `variavel` \| `parcelada` |
| due_date | date | Vencimento |
| status | enum | `pendente` \| `paga` \| `atrasada` |
| installment_current | int | Parcela atual |
| installment_total | int | Total de parcelas |
| group_id | uuid | Agrupa parcelas da mesma compra |
| paid_at | date | Data do pagamento |
| created_at | timestamp | |

---

## Estrutura do Projeto

```
lib/
├── main.dart                              # Entry point + AuthGate
├── core/
│   ├── models/
│   │   ├── user_profile.dart
│   │   ├── income.dart
│   │   ├── bill.dart
│   │   ├── category.dart
│   │   └── models.dart                    # Barrel export
│   ├── providers/
│   │   └── providers.dart                 # Riverpod providers globais
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── bills_service.dart
│   │   └── incomes_service.dart
│   ├── supabase/
│   │   └── supabase_config.dart
│   └── theme/
│       └── app_theme.dart                 # Cores, tipografia, tema dark
├── features/
│   ├── auth/
│   │   └── auth_screen.dart               # Login / Cadastro
│   ├── home/
│   │   └── home_screen.dart               # Dashboard principal
│   ├── bills/
│   │   └── bills_screen.dart              # Lista de contas com filtros
│   ├── charts/
│   │   └── charts_screen.dart             # Donut, barras, ranking
│   ├── profile/
│   │   └── profile_screen.dart            # Perfil e configurações
│   └── navigation/
│       └── main_shell.dart                # Bottom navigation bar
└── shared/
    └── widgets/
        └── glass_widgets.dart             # GlassCard, GlassBottomNav, GlassFAB, StatCard

supabase/
└── migrations/
    └── 001_initial_schema.sql             # Schema completo + RLS + triggers
```

---

## Componentes Reutilizáveis

| Componente | Descrição |
|---|---|
| `GlassCard` | Card com blur, borda glass e highlight superior |
| `GlassBottomNav` | Barra de navegação inferior glassmorphism |
| `GlassFAB` | Floating action button com expansão para Receita/Conta |
| `StatCard` | Card de estatística (ícone + label + valor) |
| `SegmentTab` | Aba segmentada (Todas / Pendentes / Pagas) |
| `_DonutPainter` | CustomPainter para gráfico donut |
| `_InsightCard` | Card de insight com ícone colorido |
| `_NavArrow` | Setas de navegação entre meses |

---

## Funcionalidades MVP

### RF01 — Cadastro e Login
- Autenticação por e-mail/senha via Supabase Auth
- Tela com tabs "Entrar" / "Criar conta"
- Opção de biometria (futuro)
- Criação automática do perfil na tabela `users`

### RF02 — Cadastro de Receitas
- Título, valor, data de recebimento
- Opção de recorrência mensal
- Bottom sheet de cadastro rápido

### RF03 — Cadastro de Contas
- Título, valor, categoria, vencimento
- Tipos: fixa, variável, parcelada
- Seleção de categoria com chips horizontais

### RF04 — Geração Automática de Parcelas
- Ao cadastrar compra parcelada, gera N linhas na tabela `bills`
- Todas compartilham o mesmo `group_id`
- Cada linha tem `installment_current` e `installment_total`

### RF05 — Marcar como Paga
- Swipe-to-pay na lista de contas
- Atualiza `status` e `paid_at`

### RF06 — Editar e Excluir
- Edição inline nos cards
- Exclusão com confirmação

### RF07 — Dashboard
- Saldo do mês (receitas - despesas)
- Cards: Receitas, Despesas, A vencer
- Resumo do orçamento (donut)
- Próximos vencimentos

### RF08 — Filtrar Contas
- Abas: Todas / Pendentes / Pagas
- Navegação entre meses

### RF09 — Gráfico Donut
- Gasto por categoria
- Legenda com percentual e valor

### RF10 — Evolução Mensal
- Gráfico de barras (últimos 3, 6 ou 12 meses)
- Destaque para o mês atual

### RF11 — Ranking
- Top 5 maiores gastos do mês
- Barra de progresso proporcional

### RF12 — Notificações
- Lembretes de vencimento via flutter_local_notifications

---

## Roadmap de Desenvolvimento

### Sprint 1 (2 semanas) — Setup e Fundação
- [x] Criar repositório e estrutura de pastas
- [x] Configurar `pubspec.yaml` com dependências
- [x] Implementar design system (cores, tema, componentes glass)
- [x] Configurar Supabase (conexão, auth)
- [x] Implementar tela de Login/Cadastro
- [x] Configurar navegação (bottom nav, rotas)
- [ ] Baixar e configurar fontes (Manrope, Inter)
- [ ] Criar projeto Flutter e gerar android/ios

### Sprint 2 (2 semanas) — CRUD e Lógica de Negócio
- [x] Criar modelos de dados (User, Income, Bill, Category)
- [x] Implementar CRUD de receitas
- [x] Implementar CRUD de contas (fixa/variável/parcelada)
- [x] Implementar geração automática de parcelas
- [x] Configurar RLS no Supabase

### Sprint 3 (2 semanas) — Dashboard e Contas
- [x] Implementar Dashboard (saldo, resumo, orçamento)
- [x] Implementar tela de Contas com filtros
- [x] Implementar swipe-to-pay
- [ ] Implementar notificações locais

### Sprint 4 (2 semanas) — Gráficos e Cadastro
- [x] Implementar gráfico donut (fl_chart)
- [x] Implementar evolução mensal (barras)
- [x] Implementar ranking de gastos
- [x] Implementar bottom sheet de cadastro
- [ ] Polimento visual e animações

### Sprint 5 (1-2 semanas) — Finalização
- [ ] Testes unitários e de widget
- [ ] Testes de usabilidade
- [ ] Ajustes visuais finais
- [ ] Configurar CI/CD (GitHub Actions)
- [ ] Publicação nas lojas (Play Store + App Store)

---

## Ambiente de Desenvolvimento

### Pré-requisitos
- Flutter SDK >= 3.24
- Dart SDK >= 3.2
- Conta no Supabase (supabase.com)
- Android Studio / VS Code
- Emulador Android ou dispositivo físico

### Configuração

1. **Clone o repositório**
```bash
git clone https://github.com/RafaelLinsMota/Nitido.git
cd Nitido
```

2. **Instale dependências**
```bash
flutter pub get
```

3. **Configure Supabase**
   - Crie um projeto no Supabase
   - Execute o SQL em `supabase/migrations/001_initial_schema.sql`
   - Copie a URL e Anon Key
   - Atualize `lib/core/supabase/supabase_config.dart`

4. **Execute**
```bash
flutter run
```

### Variáveis de Ambiente

Para build de produção, use `--dart-define`:
```bash
flutter run --dart-define=SUPABASE_URL=sua_url --dart-define=SUPABASE_ANON_KEY=sua_key
```

---

## Comandos Úteis

```bash
# Rodar o app
flutter run

# Rodar testes
flutter test

# Verificar problemas de lint
flutter analyze

# Build de release (Android)
flutter build apk --release

# Build de release (iOS)
flutter build ios --release
```

---

## Fases Futuras

### V2 — Pós-lançamento
- Orçamento por categoria com alerta de limite
- Metas de economia
- Exportação de relatórios (PDF/Excel)
- Modo offline com cache local

### V3 — Crescimento
- Múltiplas contas/carteiras
- Integração via Open Finance
- Categorização automática via IA
- Compartilhamento familiar
- Módulo de investimentos

---

## Métricas para Acompanhar

- % de usuários que cadastram 1 receita e 3 contas na primeira semana
- Retenção D7 e D30
- % de contas parceladas vs. contas simples
- Tempo médio até o primeiro lançamento

---

## Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.
