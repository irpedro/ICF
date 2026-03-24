# 🌿 Plant Sensor Analysis (ESP32 + Supabase)

Este projeto de IoT e Engenharia de Dados realiza o monitoramento autônomo do clima e umidade do solo, transmitindo os dados diretamente para um Data Lake na nuvem (Supabase/PostgreSQL) via API REST. O projeto adota a **Arquitetura Medalhão (Bronze, Silver, Gold)** e o paradigma **ELT (Extract, Load, Transform)** para garantir a qualidade, rastreabilidade e segurança dos dados.

## 🏗️ Arquitetura e Engenharia de Dados (ELT)

1. **Hardware (Edge Computing):** ESP32-C3 SuperMini programado em MicroPython.
2. **Sensores:** DHT22 (Temperatura/Umidade do Ar), Sensor de Umidade do Solo Analógico e Sensor de Luz (LDR).
3. **Eficiência Energética:** Utiliza `machine.deepsleep()` para economizar bateria entre os ciclos de leitura.
4. **Extração e Carregamento (E e L):** Envio direto do hardware para a Camada Bronze do Supabase via HTTP POST, armazenando o payload bruto em uma coluna `JSONB`. Scripts em Python funcionam como via de contingência para APIs externas.
5. **Transformação via dbt (T):** O Data Build Tool atua diretamente dentro do Data Lake operando nas camadas seguintes (não há "pasta Bronze" no dbt, pois ele lê o dado já carregado):
   * **Camada Silver:** View (`vw_leituras_silver`) responsável por descompactar o JSON, converter os tipos, ajustar o fuso horário (UTC para America/Sao_Paulo) e aplicar políticas de segurança.
   * **Camada Gold:** Modelagem de regras de negócio, cruzamento de dados e geração de alertas de saúde da planta.

## 📁 Estrutura do Projeto
* `/main.py`: O código principal de produção otimizado para a placa.
* `/ingestao_perenual.py`: Script de extração responsável por buscar os metadados das plantas na API.
* `/plant_sensor_dbt/`: Repositório de transformação de dados contendo as models em SQL (Silver/Gold) e o dicionário de dados (Seeds).
* `/poc/`: Provas de conceito e testes isolados de hardware (Display I2C, Testes de Wi-Fi).
v
## 🛠️ Pré-requisitos de Desenvolvimento (dbt)
Para rodar as transformações locais e gerar a documentação da Camada Gold, é recomendado o uso de um ambiente virtual (`venv`) para evitar conflitos de dependência.
* **Python:** Versão `3.11.x` (64-bits) recomendada por estabilidade com pacotes de dados.
* **dbt-core:** `v1.11.7`
* **dbt-postgres:** `v1.10.0`

## 📐 Calibração e Regras de Negócio (Camada Gold)

Os sensores analógicos retornam valores brutos baseados na voltagem. Para gerar métricas amigáveis e *insights* acionáveis, aplicamos as seguintes transformações:

1. **Umidade do Solo (Calibração Empírica):** Os valores brutos de voltagem do solo (0-4095) são convertidos em percentagem (0-100%) através de interpolação linear (Regra de Três) em SQL, com base em testes físicos de estresse:
   * `3050` = 0% de Umidade (Sensor seco ao ar livre)
   * `600` = 100% de Umidade (Sensor submerso em água)
2. **Luminosidade (Sensor LDR):** Categorização do sinal analógico via `CASE WHEN` (ex: Escuro, Sombra Clara, Sol Direto). *Limites em fase de calibração.*
3. **Enriquecimento Híbrido de Dados (Tabela Fato x Dimensão):** Os limites ideais de rega e luz para cada espécie são cruzados (`JOIN`) com as leituras. Para garantir precisão e resiliência, o projeto utiliza uma estratégia de contingência (`COALESCE`), sinalizada pela coluna `flg_origem_dados_confiavel`:
   * **Fonte Primária (Ouro):** Dicionário de dados estático (`limites_plantas_cientifico`), inserido via *dbt seed*, baseado em literatura agronômica de ponta (Diretrizes de produção vegetal da **ESALQ/USP**, **Boletim 100** do IAC e manuais do **Instituto Plantarum**).
   * **Fonte Secundária (Fallback):** Dados genéricos extraídos da API pública Perenual para evitar falhas sistêmicas diante de espécies não mapeadas.
  
## 🧪 Qualidade de Dados e Governança (dbt)
Para garantir a fiabilidade do pipeline e evitar o princípio de *Garbage In, Garbage Out* decorrente de possíveis falhas de hardware (ex: perda de sinal Wi-Fi ou falha no sensor), o projeto implementa rotinas de Data Quality:
* **Testes Automatizados:** Validação de integridade (`unique`, `not_null`) aplicada diretamente nas camadas Silver e Gold através de ficheiros `schema.yml`, blindando o modelo final contra dados corrompidos ou em branco.
* **Documentação e Linhagem (DAG):** Dicionário de dados mapeado desde a origem (Bronze) até ao produto final (Gold). O grafo de linhagem visual é gerado automaticamente pelo motor do dbt, garantindo total rastreabilidade do fluxo ELT.

## 🚀 Próximos Passos
- [x] **Ingestão (Bronze) & Tratamento (Silver):** Hardware enviando dados e visualização limpa configurada no Supabase.
- [x] **Calibração do Solo:** Limites físicos testados e mapeados.
- [x] **Refatoração de Código:** Script Python de ingestão renomeado para refletir a fonte.
- [x] **Dicionário Científico:** Arquivo *seed* estático no dbt criado com limites exatos da literatura agronômica.
- [x] **Camada Gold (Negócio):** View final desenvolvida aplicando o cruzamento das leituras com os limites biológicos.
- [ ] **Visualização de Dados:** Conectar o Power BI à Camada Gold para construir o dashboard histórico de monitoramento.
- [ ] **Hardware Solar & Luz:** Instalar painel solar e calibrar os limites do sensor de luminosidade (LDR).
- [ ] **Automação Ativa (Opcional):** Implementar webhooks com n8n para disparo de alertas preditivos via Telegram/Email.
