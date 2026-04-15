# 📖 Manual de Uso e Configuração

Este guia detalha a montagem física e a configuração lógica necessária para operar o sistema de monitoramento botânico.

## 🛠️ 1. Hardware (Configuração do ESP32)

### 1.1 Lista de Componentes

Para a montagem deste projeto, são utilizados os seguintes componentes:
* **Microcontrolador:** ESP32-C3 Supermini (com display incluso).
* **Sensor de Ar:** DHT22 (Temperatura e Umidade).
* **Sensor de Solo:** Sensor Capacitivo de Umidade do Solo v1.2 (Analógico).
* **Sensor de Luz:** BH1750 (Digital I2C).
* **Jumpers e Protoboard:** Para fazer a conexão entre componentes.
* **Fonte de energia:** Pode ser por um carregador USB ou uma placa solar com bateria.

### 1.2 Pinagem (Wiring)

A conexão dos periféricos ao ESP32 deve seguir a pinagem definida no firmware (`main.py`) e todos devem estar energizados ao pino de 3V (para facilitar veja fotos do hardware na pasta assets):

* **DHT22:** Pino 4.
* **Sensor de Solo (ADC):** Pino 3.
* **Barramento I2C (SCL):** Pino 6.
* **Barramento I2C (SDA):** Pino 5.
* **LED de Status:** Pino 8.

### 1.3 Credenciais e Segurança (`secrets.py`)

1. Localize o arquivo `secrets_example.py` na raiz do repositório.

2. Crie um arquivo chamado `secrets.py` na raiz do seu microcontrolador (este arquivo é ignorado pelo Git).

3. Preencha as variáveis de ambiente com suas credenciais de Wi-Fi e as chaves de API do seu projeto no Supabase.

## 💻 2. Software (Data Lake e dbt)

### 🛠️ 2.1 Pré-requisitos de Uso e Desenvolvimento (dbt)

Para rodar as transformações locais e gerar a documentação da Camada Gold, é recomendado o uso de um ambiente virtual (`venv`) para evitar conflitos de dependência.
* **Python:** Versão `3.11.x` (64-bits)
* **dbt-core:** `v1.11.7`
* **dbt-postgres:** `v1.10.0`

### 2.2 Conexão do dbt (`profiles.yml`)

Diferente do hardware, o dbt (no seu computador) precisa de um arquivo de configuração para acessar o banco. Ao rodar ele pela primeira vez ele deve fazer diversas perguntas para criar o arquivo `profiles.yml` com os dados do seu banco Supabase (Host, User, Password, Porta 6543). Sem isso, os comandos de terminal não funcionarão. Você também pode criar ou modificar esse arquivo no seu computador (caso em dúvida pesquise sobre configuração do dbt para mais detalhes).

### 2.3 Configuração da Tabela Bronze (Supabase)

Para que o hardware consiga persistir as leituras, é necessário criar a tabela de ingestão no editor SQL do Supabase uma vez antes de rodar o dispositivo. O comando abaixo cria a estrutura compatível com o contrato de dados definido no `bronze/sources.yml`:

```sql
CREATE TABLE leituras_brutas_bronze (
    id SERIAL PRIMARY KEY,
    arquivo_origem VARCHAR(50),
    dados_json JSONB,
    data_ingestao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 2.4 🔄 Manual de Operação: Catalogando Novas Espécies (Dicionário Científico)

Antes de associar um hardware a uma planta inédita, você precisa "ensinar" ao banco de dados quais são os limites de sobrevivência daquela espécie.
Abra o arquivo `data/seeds/limites_plantas_cientifico.csv` e adicione uma nova linha preenchendo as colunas:

* `nome_popular`: Nome que aparecerá no dashboard (ex: Zamioculca).
* `nome_cientifico`: Nomenclatura botânica (ex: Zamioculcas zamiifolia).
* `temp_min_c` / `temp_max_c`: Temperaturas limite em Celsius.
* `umid_ar_min_pct` / `umid_ar_max_pct`: Umidade do ar limite (0 a 100).
* `tolerancia_seca`: Rigorosamente preenchido como `ALTA`, `MEDIA` ou `BAIXA`.
* `lux_min`: Intensidade luminosa mínima para ativar fotossíntese.
* `horas_luz_minimas`: Tempo mínimo diário de sol.
* `horas_descanso_minimas`: Tempo mínimo diário de escuridão profunda.

### 2.5 🔄 Manual de Operação: Troca de Plantas e Novos Dispositivos

Como o projeto utiliza a arquitetura **SCD Tipo 2**, a gestão de sensores e vasos é feita diretamente no arquivo `seeds/cadastro_sensores.csv`. 

#### 1. Como Adicionar um Novo Sensor
Para escalar o projeto com novos ESP32:
- Adicione uma linha inédita no CSV com o novo identificador do dispositivo e a planta.

- Certifique-se de que o novo hardware esteja programado para enviar esse exato identificador no seu código principal. Para tal basta alterar a variável global `ID_DO_SENSOR` no arquivo `main.py`. 

- Insira os valores das `data_inicio` e `data_fim` com o dia e horário em que o dispositivo foi iniciado, e uma data longínqua como `2099-12-31 23:59:59`, respectivamente.

- Execute o comando `dbt build` pelo terminal, dentro da pasta plant_sensor_dbt,  para atualizar as tabelas de roteamento.

⚠️ **Atenção:** Como dito acima, o nome definido na coluna `dispositivo` (ex: `esp32_c3_supermini`) deve ser **idêntico** à string de identificação enviada pelo código no `main.py`. Caso os nomes não coincidam exatamente (incluindo letras maiúsculas e minúsculas), os dados serão carregados na Camada Bronze mas aparecerão como "Planta Desconhecida", sendo assim ignorados pelo JOIN das Camadas Gold.

#### 2. Como Registrar uma Troca de Planta

Sempre que o sensor for movido para um novo vaso:
- **Encerrar o ciclo atual:** No CSV, localize a linha do dispositivo e altere a `data_fim` para o momento exato da troca (ex: `2026-04-09 00:40:00`).

- **Iniciar o novo ciclo:** Adicione uma nova linha com o mesmo nome de `dispositivo`, o nome da nova planta, e a `data_inicio` sendo 1 minuto após o fim da anterior. Defina a `data_fim` para `2099-12-31 23:59:59`.

- Execute o comando `dbt build` pelo terminal, dentro da pasta plant_sensor_dbt,  para atualizar as tabelas de roteamento.

- Novamente, a arquitetura SCD2 (Slowly Changing Dimension) detectará a mudança de vínculo e iniciará um novo histórico automaticamente, preservando os dados da planta anterior sem necessidade de intervenção manual no banco de dados.

# ⚠️ 3. Troubleshooting (Resolução de Problemas)

### 🔴 O Hardware não envia dados
Se você estiver utilizando o Display OLED para debug, verifique as mensagens de status:
* **"Erro DB":** O ESP32 conectou ao Wi-Fi, mas o banco recusou o payload. Verifique se a tabela `leituras_brutas_bronze` existe e se as chaves no `secrets.py` estão corretas.

* **"E E E...":** Falha na conexão Wi-Fi. Certifique-se de que a rede é 2.4GHz.

### 🟡 Dispositivo ou Planta não aparecem no Banco de Dados
* **Divergência de Nomes (String Mismatch):** O sistema é *Case Sensitive*. O nome configurado na variável `DEVICE_ID` do seu arquivo `main.py` deve ser **exatamente igual** ao nome inserido na coluna `dispositivo` do arquivo `cadastro_sensores.csv`. Um espaço a mais ou letra maiúscula errada fará o dbt ignorar os dados daquela placa na Camada Gold.

### 🔵 Problemas ao Adicionar Nova Planta (Erros de Histórico)
* **Conflito de Datas (Overlapping):** A arquitetura SCD Tipo 2 exige uma cronologia contínua perfeita. Se os dados da planta nova não estiverem processando corretamente, verifique as datas no `cadastro_sensores.csv`. A `data_fim` da planta antiga deve ser obrigatoriamente anterior (ou igual) à `data_inicio` da planta nova. Além disso, respeite o formato rígido: `YYYY-MM-DD HH:MM:SS`.

### 🟤 Umidade do Solo Irreal (0% ou 100%)
* **Limites de Calibração:** A lógica de conversão utiliza os limites físicos `3050` (ar seco) e `1420` (solo saturado). Se o seu sensor operar com uma faixa elétrica diferente faça a calibração e ajuste estes valores no SQL da Camada Gold.

* **Lençol Freático Suspenso (Valores Altíssimos Constantes):** Se o sensor for espetado muito no fundo do vaso, ele começará a ler a água parada no fundo (tensão capilar da terra). Posicione o sensor ligeiramente mais para cima (1 ou 2 cm) e evite tocar a base do vaso.

* **Water Channeling:** Verifique se o sensor foi inserido na diagonal. Sensores inseridos 100% na vertical facilitam o escoamento da água da rega rente ao corpo da placa, gerando túneis úmidos e picos falsos de 100%.