# 🌿 Plant Sensor Analysis (ESP32 + Supabase)

Este projeto de IoT e Engenharia de Dados realiza o monitoramento autônomo do clima e umidade do solo, transmitindo os dados diretamente para um Data Lake na nuvem (Supabase/PostgreSQL) via API REST. O projeto adota a **Arquitetura Medalhão (Bronze, Silver, Gold)** para garantir a qualidade, rastreabilidade e segurança dos dados.

## 🏗️ Arquitetura e Engenharia de Dados

1. **Hardware (Edge Computing):** ESP32-C3 SuperMini programado em MicroPython.
2. **Sensores:** DHT22 (Temperatura/Umidade do Ar), Sensor de Umidade do Solo Analógico e Sensor de Luz (LDR).
3. **Eficiência Energética:** Utiliza `machine.deepsleep()` para economizar bateria entre os ciclos de leitura.
4. **Camada Bronze (Ingestão):** Envio direto para o Supabase via HTTP POST, armazenando o payload bruto em uma coluna `JSONB`.
5. **Camada Silver (Tratamento):** View (`vw_leituras_silver`) responsável por descompactar o JSON, converter os tipos de dados, ajustar o fuso horário (UTC para America/Sao_Paulo) e aplicar políticas de segurança de acesso (*Secure View*).

## 📁 Estrutura do Projeto
* `/main.py`: O código principal de produção otimizado para a placa.
* `/ingestao_perenual.py`: Script de extração (ETL) responsável por buscar os metadados das plantas na API.
* `/poc/`: Provas de conceito e testes isolados de hardware (Display I2C, Testes de Wi-Fi).

## 📐 Calibração e Regras de Negócio (Camada Gold)

Os sensores analógicos retornam valores brutos baseados na voltagem. Para gerar métricas amigáveis e *insights* acionáveis para o usuário final, aplicamos as seguintes transformações:

1. **Umidade do Solo (Calibração Empírica):** Os valores brutos de voltagem do solo (0-4095) são convertidos em percentagem (0-100%) através de interpolação linear (Regra de Três) em SQL, com base em testes físicos de estresse:
   * `3050` = 0% de Umidade (Sensor seco ao ar livre)
   * `600` = 100% de Umidade (Sensor submerso em água)
2. **Luminosidade (Sensor LDR):** Categorização do sinal analógico via `CASE WHEN` (ex: Escuro, Sombra Clara, Sol Direto). *Limites em fase de calibração.*
3. **Enriquecimento Híbrido de Dados (Tabela Dimensão):** Os limites ideais de rega e luz para cada espécie de planta são cruzados (`JOIN`) com as leituras da Tabela Fato. Para garantir precisão, o projeto utiliza uma estratégia de contingência (`COALESCE`):
   * **Fonte Primária:** Dicionário de dados estático baseado em literaturas agronômicas e científicas (ex: ESALQ/Embrapa), inserido via dbt seed.
   * **Fonte Secundária (Fallback):** Dados genéricos extraídos da API pública Perenual para garantir que o sistema não falhe diante de espécies não mapeadas.

## 🚀 Próximos Passos
- [x] **Ingestão (Bronze) & Tratamento (Silver):** Hardware enviando dados e visualização limpa configurada no Supabase.
- [x] **Calibração do Solo:** Limites físicos testados e mapeados.
- [x] **Refatoração de Código:** Script Python de ingestão renomeado para refletir a fonte.
- [ ] **Dicionário Científico:** Criar o *seed* estático no dbt com limites exatos da literatura agronômica.
- [ ] **Camada Gold (Negócio):** Desenvolver a view final aplicando a Regra de Três (%) e o cruzamento das fontes com `COALESCE`.
- [ ] **Visualização de Dados:** Conectar o Power BI à Camada Gold para construir o dashboard histórico de monitoramento.
- [ ] **Hardware Solar & Luz:** Instalar painel solar e calibrar os limites do sensor de luminosidade (LDR).
- [ ] **Automação Ativa (Opcional):** Implementar webhooks com n8n para disparo de alertas preditivos via Telegram/Email.
