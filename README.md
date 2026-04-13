# 🌿 Plant Sensor Analysis (ESP32 + Supabase)

Este projeto de IoT e Engenharia de Dados realiza o monitoramento autônomo do clima e umidade do solo, transmitindo os dados diretamente para um Data Lake na nuvem (Supabase/PostgreSQL) via API REST. O projeto adota a **Arquitetura Medalhão (Bronze, Silver, Gold)** e o paradigma **ELT (Extract, Load, Transform)** para garantir a qualidade, rastreabilidade e segurança dos dados.

## 📊 Dashboard Interativo (Power BI)
*Interaja com o relatório ao vivo abaixo. Utilize as setas no rodapé do painel para navegar entre as visões de Tempo Real, Resumo Tático (7 Dias) e Visão Estratégica Mensal.*

🔗 **[Clique aqui para abrir o Dashboard em tela cheia em uma nova aba](https://app.powerbi.com/view?r=eyJrIjoiOGE3NzM3YWQtZGVhMC00OTc4LTliOTEtMTU5MDE3ZTk1MjgyIiwidCI6IjdlOTNlMjg2LWIyOWEtNDQ1NC1hNDFhLWU4NDE5ZWM5ZGViNSJ9&pageName=fdfbc4c6a69c2e7bc151)**

<a href="https://app.powerbi.com/view?r=eyJrIjoiOGE3NzM3YWQtZGVhMC00OTc4LTliOTEtMTU5MDE3ZTk1MjgyIiwidCI6IjdlOTNlMjg2LWIyOWEtNDQ1NC1hNDFhLWU4NDE5ZWM5ZGViNSJ9&pageName=fdfbc4c6a69c2e7bc151" target="_blank">
  <img src="dashboard_preview.png" alt="Preview do Dashboard Interativo" width="100%">
</a>

---

### 🔄 Manual de Operação: Troca de Plantas e Novos Dispositivos

Como o projeto utiliza a arquitetura **SCD Tipo 2**, a gestão de sensores e vasos é feita diretamente no arquivo `seeds/cadastro_sensores.csv`. 

#### 1. Sincronização Obrigatória (Hardware x Banco)
⚠️ **Atenção:** O nome definido na coluna `dispositivo` (ex: `esp32_c3_supermini`) deve ser **idêntico** à string de identificação enviada pelo código no `main.py`. Atualmente, essa identificação é feita diretamente no payload JSON do hardware. Caso os nomes não coincidam exatamente (incluindo letras maiúsculas e minúsculas), os dados serão carregados na Camada Bronze mas aparecerão como "Planta Desconhecida" no Power BI.

#### 2. Como Registrar uma Troca de Planta
Sempre que o sensor for movido para um novo vaso:
- **Encerrar o ciclo atual:** No CSV, localize a linha do dispositivo e altere a `data_fim` para o momento exato da troca (ex: `2026-04-09 00:40:00`).
- **Iniciar o novo ciclo:** Adicione uma nova linha com o mesmo nome de `dispositivo`, o nome da nova planta, e a `data_inicio` sendo 1 segundo após o fim da anterior. Defina a `data_fim` para `2099-12-31 23:59:59`.

#### 3. Como Adicionar um Novo Sensor
Para escalar o projeto com novos ESP32:
- Adicione uma linha inédita no CSV com o novo identificador do dispositivo.
- Certifique-se de que o novo hardware esteja programado para enviar esse exato identificador no seu código principal. Para tal basta alterar a variável global `ID_DO_SENSOR` no arquivo `main.py`. A arquitetura SCD2 (Slowly Changing Dimension) detectará a mudança de vínculo e iniciará um novo histórico automaticamente, preservando os dados da planta anterior sem necessidade de intervenção manual no banco de dados.
- Execute o comando `dbt build` para atualizar as tabelas de roteamento.

## 🏗️ Arquitetura e Engenharia de Dados (ELT)

1. **Hardware (Edge Computing & Segurança):** ESP32-C3 SuperMini programado em MicroPython. Implementa cofre de senhas (`secrets.py`) para isolamento de credenciais e utiliza um Display OLED (SSD1306) via I2C para observabilidade e telemetria física em tempo real.
2. **Sensores:** DHT22 (Temperatura/Umidade do Ar), Sensor de Umidade do Solo Analógico e Sensor de Luz Digital (BH1750 via I2C).
3. **Eficiência Energética:** Utiliza `machine.deepsleep()` para economizar bateria entre os ciclos de leitura.
4. **Extração e Carregamento (E e L):** Envio direto do hardware para a Camada Bronze do Supabase via HTTP POST, armazenando o payload bruto em uma coluna `JSONB`. Scripts em Python funcionam como via de contingência para APIs externas.
5. **Transformação via dbt (T):** O Data Build Tool atua diretamente dentro do Data Lake operando nas camadas seguintes:
   
   * **Camada Silver:** View (`vw_leituras_silver`) responsável por descompactar o JSON, converter os tipos, ajustar o fuso horário e aplicar políticas de segurança.

   * **Camada Gold (Calibração & Agregação):** Dividida em Fato Granulada (Aplica regra de três invertida travada para calibrar o sensor de solo de ADC para % e cruza com limites biológicos) e Fato Agregada (Resumo diário focando no cálculo de DLI - Daily Light Integral).
   
6. **Rastreabilidade Histórica (SCD Tipo 2):** A modelagem utiliza *Slowly Changing Dimensions* do Tipo 2 para garantir que o histórico passado permaneça imutável em caso de troca física de plantas no mesmo hardware.
7. **Orquestração e Alertas (Make.com):** Multiplexador na nuvem que consome o banco de dados e alimenta um Bot no Telegram. Conta com envio de Alertas Críticos (solo seco com sistema de *cooldown*) e um Menu Interativo para solicitação de relatórios de saúde sob demanda.
8. **Visualização Automática (Power BI):** Dashboard interativo conectado diretamente ao Supabase via Pooler de conexões. Configurado com rotinas de *Scheduled Refresh* (Atualização Agendada) no Power BI Service para garantir dados sempre atualizados múltiplas vezes ao dia.
  
    * **Star Schema & Bridge Table:** Implementação de uma tabela de dimensão única (`Dim_Filtro_Plantas`) gerada via DAX. Essa "Tabela Ponte" atua como o comando central do dashboard, permitindo que um único seletor filtre simultaneamente tabelas de diferentes granularidades (leituras minuto a minuto vs. agregados diários).

    * **Filtro Universal de Dispositivos:** O dashboard utiliza o identificador único (Hardware + Planta + Data) para garantir que o usuário nunca visualize dados sobrepostos de duas culturas diferentes no mesmo gráfico.

## 📁 Estrutura do Projeto
* `/main.py`: O código principal de produção otimizado para a placa.
* `/ingestao_perenual.py`: Script de extração responsável por buscar os metadados das plantas na API.
* `/plant_sensor_dbt/`: Repositório de transformação de dados contendo as models em SQL (Silver/Gold) e o dicionário de dados (Seeds).
* `/poc/`: Provas de conceito e testes isolados de hardware.

## 🛠️ Pré-requisitos de Desenvolvimento (dbt)
Para rodar as transformações locais e gerar a documentação da Camada Gold, é recomendado o uso de um ambiente virtual (`venv`) para evitar conflitos de dependência.
* **Python:** Versão `3.11.x` (64-bits)
* **dbt-core:** `v1.11.7`
* **dbt-postgres:** `v1.10.0`

## 📐 Calibração e Regras de Negócio (Camada Gold)

Alguns dos sensores retornam valores brutos. Para gerar métricas amigáveis e *insights* acionáveis, aplicamos as seguintes transformações:

1. **Umidade do Solo: O Abismo entre IoT e Agronomia (VWC vs. Tensão)**
  Durante o desenvolvimento, foi identificado um grave "Impedance Mismatch" entre as recomendações de fábrica do hardware e a biologia real da planta. O sensor não mede "água" diretamente, mas sim a **Constante Dielétrica ($\kappa$)** do meio.

    * **O Chão Absoluto (Ar = 0%):** O ar possui $\kappa \approx 1$ e os minerais secos do solo possuem um $\kappa$ muito baixo (entre 3 e 5). Como a terra esturricada é basicamente uma mistura de ar e minerais, a sua constante dielétrica resultante é insignificante se comparada à da água ($\kappa \approx 80$). Por isso, cravamos a calibração de **3050 ADC (Ar)** como o nosso "zero absoluto" (solo hidrofóbico e estresse hídrico total). É uma referência universal imutável.
   
    * **A Ilusão da Água Pura (O Teto Relativo):** A água pura possui uma constante elétrica altíssima ($\kappa \approx 80$). A calibração padrão de mercado (água pura = 100%) "esmaga" a escala de leitura. Na escala científica VWC (*Conteúdo Volumétrico de Água*), a terra atinge saturação máxima ("lama") com cerca de 45% de volume de água (que possui um $\kappa$ muito menor que a água pura). Calibrar o limite na água pura tornava metade da capacidade analítica do gráfico inútil.
   
    * **Volume vs. Força (O Ponto Cego do Sensor):** Artigos de agricultura profissional alertam que sensores capacitivos medem apenas o *Volume* de água. No entanto, a planta sobrevive baseada no *Potencial Matricial* (a força necessária para sugar a água do solo). Por exemplo, 30% de água numa terra arenosa é fácil de absorver, mas 30% de água numa argila densa mata a planta de sede, pois a argila "prende" as moléculas de água. O nosso hardware IoT de baixo custo não tem capacidade física para ler essa força.
   
    * **O Pivot de Engenharia (A Calibração na Lama):** Para mitigar essas limitações físicas sem encarecer o projeto com tensiômetros e sensores profissionais, descartamos a calibração na água e calibramos o sensor na lama do **próprio substrato**. Isso converteu a leitura para uma **Escala Relativa Otimizada** (onde 100% = saturação máxima daquele solo específico), garantindo gráficos de alta resolução. Assim, a regra de três invertida na Camada Gold ficou travada em:

      * `3050` ADC = 0% de Umidade (Sensor no ar / Solo esturricado)
      * `1420` ADC = 100% de Umidade (Terra em saturação máxima / Lama)

    * ⚠️ **Aviso Crítico de Manutenção (Física do Raio de Influência):**
     O sensor lê a umidade num raio de apenas ~2 a 3 cm ao redor da sua placa. Devido a esta física:

      - **O tamanho do vaso é irrelevante:** A calibração de limites feita num copo de 200ml funcionará perfeitamente num vaso de 50 litros.

      - **O TIPO de terra é crucial:** Como a calibração está atrelada à condutividade elétrica de um substrato específico, se você mudar a planta para uma terra com composição radicalmente diferente (ex: rica em areia vs. rica em argila), **é estritamente recomendável recalibrar o limite de 100% com a nova terra**.

      - **Fenômeno do Lençol Freático Suspenso:** Em vasos rasos, a gravidade não vence a capilaridade da terra. O sensor deve ser posicionado estrategicamente no eixo-Z (zona das raízes), fugindo do fundo do vaso para evitar leituras falsas de saturação extrema.

2. **Conversão de Luminosidade (Lux para PPFD/PAR):** O hardware capta a intensidade da luz em *Lux*, uma métrica focada na percepção visual humana. No entanto, as regras de negócio agronômicas exigem a medição da Radiação Fotossinteticamente Ativa (PAR), medida em PPFD (µmol/m²/s). 

   * **Transformação Analítica:** Na Camada Gold, os dados brutos de Lux sofrem uma transformação matemática para refletir a energia real disponível para a fotossíntese.

   * **Fator de Conversão:** Utilizando a constante de aproximação para espectro de luz natural, a fórmula aplicada no dbt é `PPFD = Lux * 0.0185` (ou `Lux / 54`). Isso garante que a contagem de fótons seja biologicamente precisa para a regra de negócio da espécie cadastrada.

3. **Enriquecimento Híbrido de Dados (Tabela Fato x Dimensão):** Os limites ideais de rega e luz para cada espécie são cruzados (`JOIN`) com as leituras. Utiliza-se a função `COALESCE` para priorizar a fonte primária (dicionário oficial ESALQ/USP em dbt seed) e usar a API Perenual apenas como *fallback*.
  
## 🧪 Qualidade de Dados e Governança (dbt)
* **Documentação e Linhagem (DAG):** Dicionário de dados mapeado desde a origem (Bronze) até ao produto final (Gold). 
  * 🔗 **[Clique aqui para acessar o Dicionário de Dados Interativo (dbt docs)](https://irpedro.github.io/ICF/)** gerado automaticamente via CI/CD (GitHub Actions).
* **Testes Automatizados:** Validação de integridade (`unique`, `not_null`) aplicada diretamente nas camadas Silver e Gold através do ficheiro `schema.yml`.

## 🤖 Automação e Alertas (Make.com + Telegram)

Para fechar o ciclo de dados (do hardware até a palma da mão), foi implementada uma camada de orquestração rodando 100% na nuvem utilizando o **Make.com**. A arquitetura foi desenhada no padrão *Scheduled Multiplexer* para otimizar o uso da infraestrutura gratuita, avaliando múltiplas regras de negócio em uma única execução.

O fluxo é ativado a cada 6 horas e consome diretamente a Camada Gold do dbt (Supabase), ramificando-se em três rotas analíticas distintas:

* **Rota A (Observabilidade de Hardware):** Verifica a saúde da infraestrutura calculando o `minutos_offline` (Timestamp do Servidor vs. Último envio do ESP32). Dispara alertas críticos se a placa perder conexão Wi-Fi ou bateria.
* **Rota B (Prevenção e Saúde da Planta):** Monitoriza regras de negócio críticas, como "Solo Seco". Possui um sistema integrado de *Cooldown* (usando Make Data Stores) que bloqueia envios repetidos por 12 horas, atuando como um filtro Anti-Spam.
* **Rota C (Fechamento do Dia):** Protegida por um filtro de *Timezone* que só abre a catraca às 20h. Faz um `LEFT JOIN` on-the-fly entre a foto de momento (tabela granulada) e as agregações do dbt (tabela diária), enviando um boletim completo com:
    * Máximas e Mínimas do dia (Temperatura e Umidade).
    * *Daily Light Integral* (Horas de Sol Útil e Diagnóstico de Saúde Luminosa).
    * Uptime real do sistema (% de confiabilidade dos dados nas últimas 24h).

> 💡 **Nota de Reprodutibilidade:** Os cenários do Make.com e o Bot do Telegram possuem chaves de API privadas (Hardcoded Tokens) e não estão diretamente disponíveis no repositório. Para replicar este projeto, será necessário configurar o seu próprio *bot* via BotFather e conectar os webhooks da sua conta Make ao seu banco de dados PostgreSQL. Para conferir a estrutura visual dos cenários, consulte a pasta `/docs/images`.

## 🚀 Visão de Futuro e Escalabilidade

O projeto foi desenhado seguindo princípios de arquitetura modular, permitindo a sua evolução de uma ferramenta de monitorização pessoal para uma plataforma escalável (SaaS). As próximas etapas de desenvolvimento focam-se em:

### 1. Desacoplamento e Multi-tenancy
Atualmente, as notificações estão configuradas para um utilizador administrativo. A evolução prevê a criação de uma camada de gestão de utilizadores no PostgreSQL, onde cada sensor é vinculado a um `id_utilizador`. 
- **Notificações Dinâmicas:** O motor de regras no Make.com passará a consultar o `telegram_chat_id` diretamente da base de dados, permitindo que o sistema suporte múltiplos utilizadores em simultâneo.

### 2. Interface de Utilizador (Portal de Gestão)
Para eliminar a necessidade de configuração via SQL por parte do utilizador, está prevista a criação de um Front-end unificado.
- **Provisionamento Self-service:** Interface para registo de novos sensores e mapeamento de espécies botânicas.
- **Dashboards Dinâmicos:** Integração com Power BI através de filtragem dinâmica de parâmetros, permitindo que o utilizador visualize os dados específicos de cada sensor de forma isolada num único ambiente centralizado.

## 🚀 Próximos Passos

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
- [ ] **Reset da Camada Bronze:** Limpeza dos dados de laboratório (Truncate) via SQL para início do log histórico oficial de produção.
- [x] **Refatoração de Código (Hardware):** Implementar variável global `ID_DO_SENSOR` no `main.py` para facilitar a escalabilidade de novos dispositivos.
- [ ] **Política de Retenção de Dados:** Implementar rotina no Supabase (via *pg_cron* ou Trigger) para deletar logs da tabela `leituras_brutas_bronze` mais velhos que 3 meses, otimizando o armazenamento.
- [x] **Teste de Estresse Botânico:** Executar a troca temporal (SCD2) para suculenta no intuito de forçar o disparo de alertas no Telegram.
- [x] **Documentação Visual e Vídeo:** Criar diretório `/docs/images` e produzir o vídeo demonstrativo do "Produto de Dados".