# 🌿 Plant Sensor Analysis (ESP32 + Supabase)

Este projeto de IoT e Engenharia de Dados realiza o monitoramento autônomo do clima e umidade do solo, transmitindo os dados diretamente para um Data Lake na nuvem (Supabase/PostgreSQL) via API REST. O projeto adota a **Arquitetura Medalhão (Bronze, Silver, Gold)** e o paradigma **ELT (Extract, Load, Transform)** para garantir a qualidade, rastreabilidade e segurança dos dados.

## 🏗️ Arquitetura e Engenharia de Dados (ELT)

1. **Hardware (Edge Computing):** ESP32-C3 SuperMini programado em MicroPython.
2. **Sensores:** DHT22 (Temperatura/Umidade do Ar), Sensor de Umidade do Solo Analógico e Sensor de Luz Digital (BH1750 via I2C).
3. **Eficiência Energética:** Utiliza `machine.deepsleep()` para economizar bateria entre os ciclos de leitura.
4. **Extração e Carregamento (E e L):** Envio direto do hardware para a Camada Bronze do Supabase via HTTP POST, armazenando o payload bruto em uma coluna `JSONB`. Scripts em Python funcionam como via de contingência para APIs externas.
5. **Transformação via dbt (T):** O Data Build Tool atua diretamente dentro do Data Lake operando nas camadas seguintes:
   * **Camada Silver:** View (`vw_leituras_silver`) responsável por descompactar o JSON, converter os tipos, ajustar o fuso horário e aplicar políticas de segurança.
   * **Camada Gold (Roteamento Dinâmico & Agregação):** Dividida em duas *Fato* principais:
     * **Granulada (Tempo Real):** Cruzamento das leituras de momento com os limites biológicos via seed (`cadastro_sensores.csv`). Gera alertas imediatos de temperatura e rega.
     * **Agregada (Resumo Diário):** Modelagem focada no *Daily Light Integral* (DLI), agrupando os dados de luminosidade do sensor BH1750 para calcular o tempo total de exposição solar útil no dia.

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

Os sensores retornam valores brutos. Para gerar métricas amigáveis e *insights* acionáveis, aplicamos as seguintes transformações:

1. **Umidade do Solo (Calibração Empírica):** Os valores brutos de voltagem (0-4095) são convertidos em percentagem (0-100%) através de interpolação linear (Regra de Três) em SQL:
   * `3050` = 0% de Umidade (Sensor seco)
   * `600` = 100% de Umidade (Sensor submerso)
2. **Luminosidade (Sensor BH1750 I2C):** Leitura de altíssima precisão em Lux. Os dados são agregados na tabela `gold_diaria_monitorizacao` para definir a saúde fotossintética do dia.
   * Foi implementada uma separação semântica entre o limiar físico de escuridão (< 50 lux) para medir o fotoperíodo, e o limite biológico de fotossíntese (lux_min) para gerar alertas de saúde da planta.
3. **Enriquecimento Híbrido de Dados (Tabela Fato x Dimensão):** Os limites ideais de rega e luz para cada espécie são cruzados (`JOIN`) com as leituras. Utiliza-se a função `COALESCE` para priorizar a fonte primária (dicionário oficial ESALQ/USP em dbt seed) e usar a API Perenual apenas como *fallback*.
  
## 🧪 Qualidade de Dados e Governança (dbt)
* **Testes Automatizados:** Validação de integridade (`unique`, `not_null`) aplicada diretamente nas camadas Silver e Gold através do ficheiro `schema.yml`.
* **Documentação e Linhagem (DAG):** Dicionário de dados mapeado desde a origem (Bronze) até ao produto final (Gold). O grafo de linhagem visual é gerado automaticamente pelo dbt (`dbt docs serve`).

## 🚀 Próximos Passos
- [x] **Ingestão (Bronze) & Tratamento (Silver):** Hardware enviando dados e visualização limpa configurada no Supabase.
- [x] **Calibração do Solo:** Limites físicos testados e mapeados.
- [x] **Dicionário Científico:** Arquivo *seed* estático no dbt criado com limites da literatura agronômica.
- [x] **Camada Gold (Negócio):** View final desenvolvida cruzando leituras com limites biológicos.

**Frente 1: Hardware & Engenharia de Dados (Coleta de Luz)**
- [x] **Configuração do BH1750:** Otimizado o `main.py` para utilizar a biblioteca do sensor de luz digital I2C (pinos 5 e 6).
- [x] **Nova Modelagem dbt (DLI):** Desenvolvida a tabela `gold_diaria_monitorizacao` para calcular o acúmulo de horas de luz úteis diárias.

**Frente 2: Visualização & Business Intelligence (Power BI)**
- [x] **Resolução de Infraestrutura:** Conexão direta Power BI Desktop -> Supabase Pooler configurada, ignorando bloqueios de certificado SSL da nuvem.
- [x] **Construção do Dashboard:** Visualizações de tempo real (Página 1) e gráficos de acompanhamento agregado (Página 2) conectadas ao modelo semântico local.
- [ ] **Refinamento de UI/UX:** Aplicar Dark Mode e transformar os alertas tabulares em Cartões KPI dinâmicos.

**Frente 3: Refinamento e Teste Final**
- [ ] **Reset da Camada Bronze:** Apagar os dados de teste ("lixo" de desenvolvimento) e reativar o teste `not_null` da luminosidade no `schema.yml` da Silver.
- [ ] **Automação Ativa (Opcional):** Implementar webhooks com n8n para disparo de alertas.
- [ ] **Teste Final em Produção:** Testar e monitorar a planta com o projeto completo rodando em Deep Sleep.