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

## 🚀 Próximos Passos (Data Engineering)
- [ ] Modelagem dimensional e calibração dos sensores usando SQL/dbt (Camada Silver/Gold).
- [ ] Criação de painel de visualização (BI) com Metabase ou Power BI.
