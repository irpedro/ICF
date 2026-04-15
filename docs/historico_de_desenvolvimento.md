## 🚀 Próximos Passos (Completo)

**Frente 1: Engenharia de Dados & dbt (Supabase)**
- [x] **Ingestão Raw:** Tabela Bronze de *Log Append-Only* recebendo JSON do ESP32 via REST API.
- [x] **Normalização Silver:** Desestruturação do JSON (`dados_json->>'temperature_c'`) com tipagem rígida (CAST) e fuso horário corrigido para `America/Sao_Paulo`.
- [x] **Calibração de Hardware (Gold):** Conversão dos valores brutos (ADC) do sensor capacitivo de solo para percentual (0-100%) através de regra de três invertida travada (limites de 3050 a 600).
- [x] **Master Data (Seeds):** Criação de tabelas de dimensão em CSV com limites biológicos de 6+ espécies de plantas baseados em literatura botânica.
- [x] **Modelagem de Histórico (SCD Tipo 2):** Implementação de *Slowly Changing Dimensions* na tabela de dimensões (`cadastro_sensores.csv`) utilizando *Range JOINs* na Camada Gold. Garante a imutabilidade do histórico botânico em caso de troca física de plantas usando o mesmo hardware.
- [x] **Enriquecimento Gold:** Views materializadas aplicando regras de negócio e limites biológicos (Alertas de saúde) sobre os dados limpos.
- [x] **Cálculo de DLI (Daily Light Integral):** CTE avançada na tabela `gold_diaria_monitorizacao` para calcular o acúmulo de horas de luz úteis diárias.

**Frente 2: Visualização & Business Intelligence (Power BI)**
- [x] **Resolução de Infraestrutura:** Conexão direta Power BI Desktop -> Supabase Pooler configurada, ignorando bloqueios de certificado SSL da nuvem.
- [x] **Construção do Dashboard:** Visualizações de tempo real (Página 1) e gráficos de acompanhamento agregado (Página 2, 3 e 4) conectadas ao modelo semântico local.
- [x] **Refinamento de UI/UX:** Dark Mode aplicado, com métricas complexas transformadas em Cartões KPI dinâmicos e Tooltips.
- [x] **Deploy:** Publicação do painel interativo diretamente no GitHub (Web Embed).
- [x] **Modelagem Star Schema Avançada:** Criação de Tabela Dimensão (Bridge Table) via DAX (`DISTINCT`) e relacionamentos unidirecionais `1:*` para orquestrar o filtro de *Slowly Changing Dimensions* (SCD Tipo 2). Isso garante o isolamento perfeito do histórico de sensores e botânica, impedindo vazamento de dados entre plantas diferentes que usaram o mesmo hardware.
- [x] **Integração Dinâmica via API:** Customização avançada em linguagem M (Power Query) no Editor Avançado para forçar a ingestão e tipagem em tempo real de novas colunas criadas dinamicamente no Supabase.

**Frente 3: Edge Computing, Orquestração e Entrega**
- [x] **Segurança e Observabilidade na Borda:** Separação de credenciais em `secrets.py` e programação de Display OLED (SSD1306) via I2C para telemetria e debug físico em tempo real.
- [x] **Automação e Orquestração (Make.com):** Multiplexador de rotas com sistema de *Cooldown* para alertas críticos (solo seco) e relatórios diários via Telegram Bot.
- [x] **Deploy Físico (MVP):** Instalação do hardware em ambiente real (Aloe Vera).
- [x] **Evolução de Arquitetura (SCD2):** Ajuste de contrato no `schema.yml` para habilitar a rastreabilidade temporal dos sensores sem quebrar compilações.
- [x] **Reset da Camada Bronze:** Limpeza dos dados de laboratório (Truncate) via SQL para início do log histórico oficial de produção.
- [x] **Refatoração de Código (Hardware):** Implementar variável global `ID_DO_SENSOR` no `main.py` para facilitar a escalabilidade de novos dispositivos.
- [x] **Teste de Estresse Botânico:** Executar a troca temporal (SCD2) para suculenta no intuito de forçar o disparo de alertas no Telegram.
- [x] **Documentação Visual e Vídeo:** Criar diretório `/docs/images` e produzir o vídeo demonstrativo do "Produto de Dados".
- [Descartado] **Política de Retenção de Dados:** Implementar rotina no Supabase (via *pg_cron* ou Trigger) para deletar logs da tabela `leituras_brutas_bronze` mais velhos que 3 meses, otimizando o armazenamento.