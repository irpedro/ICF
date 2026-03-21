# 🌿 Plant Sensor Analysis (ESP32 + Supabase)

Este projeto de IoT e Engenharia de Dados realiza o monitoramento autônomo do clima e umidade do solo, transmitindo os dados diretamente para um Data Lake na nuvem (Supabase/PostgreSQL) via API REST.

## 🏗️ Arquitetura
1. **Hardware (Edge Computing):** ESP32-C3 SuperMini programado em MicroPython.
2. **Sensores:** DHT22 (Temperatura/Umidade do Ar), Sensor de Umidade do Solo Analógico e Sensor de Luz (LDR).
3. **Eficiência Energética:** Utiliza `machine.deepsleep()` para economizar bateria entre os ciclos de leitura.
4. **Ingestão de Dados (Camada Bronze):** Envio direto para o Supabase via HTTP POST, armazenando o payload bruto em uma coluna `JSONB`.

## 📁 Estrutura do Projeto
* `/main.py`: O código principal de produção otimizado para a placa.
* `/poc/`: Provas de conceito e testes isolados de hardware (Display I2C, Testes de Wi-Fi).

## 📐 Calibração e Regras de Negócio (Camada Gold)
Os sensores analógicos retornam valores brutos (0 a 4095) baseados na voltagem. Para gerar métricas amigáveis para o usuário final, aplicamos as seguintes transformações em SQL (via dbt):

* **Umidade do Solo:** Interpolação linear (Regra de Três). 
  * `Valor Seco (Ex: 3500)` = 0% de Umidade
  * `Valor Submerso em Água (Ex: 1200)` = 100% de Umidade
* **Luminosidade (LDR):** Categorização via `CASE WHEN`.
  * `< 1000` = Escuro
  * `1000 a 2500` = Sombra Clara
  * `> 2500` = Sol Direto
 
## 🧠 Regras de Negócio e Enriquecimento de Dados (Camada Gold)

Para transformar dados brutos de sensores em *insights* acionáveis, este projeto utiliza uma arquitetura de dados moderna (ELT) com modelagem dimensional:

1. **Calibração Analógica:** Os valores brutos de voltagem do solo (0-4095) são convertidos em percentagem (0-100%) através de interpolação linear (Regra de Três) em SQL.
2. **Classificação de Luminosidade:** O sinal do sensor LDR é categorizado ('Escuro', 'Sombra', 'Sol Direto') usando blocos `CASE WHEN`.
3. **Enriquecimento com API (Tabela Dimensão):** Os limites ideais de humidade e luz para cada espécie de planta não são adivinhados. Eles são extraídos de APIs botânicas públicas e carregados numa tabela dimensional local (`dim_plantas`). 
4. **Cruzamento de Dados:** As leituras da Tabela Fato (ESP32) são cruzadas (`JOIN`) com a Tabela Dimensão (Botânica) para gerar alertas reais, como *"Humidade a 20%: Crítico para esta espécie"*.

## 🚀 Próximos Passos (Data Engineering)
- [ ] Modelagem Botânica (API -> Dimensão): Criar a tabela dim_plantas no Supabase. Escrever um script Python local para extrair os limites de água e luz de uma API botânica e carregar nessa tabela.
- [ ] Calibração e Cruzamento (Camada Gold): Fazer a matemática no SQL (Regra de Três para o solo) e cruzar as leituras da Tabela Fato (ESP32) com a Tabela Dimensão (dim_plantas).
- [ ] Transformação Profissional (dbt): Migrar esta lógica para o dbt, versionando o pipeline de transformação.
- [ ] Visualização de Dados (Power BI / Metabase): Ligar a ferramenta de BI diretamente à Camada Gold do Supabase para construir o dashboard de monitorização e alertas visuais.
- [ ] Documentação: Manter o README.md atualizado com o diagrama desta arquitetura.
