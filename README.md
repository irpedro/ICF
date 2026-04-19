# 🌿 Plant Sensor Analysis

[![Testes de Qualidade (dbt)](https://img.shields.io/github/actions/workflow/status/irpedro/ICF/dbt-docs.yml?label=Testes%20dbt&logo=github&logoColor=white)](https://github.com/irpedro/ICF/actions)
[![Documentação dbt](https://img.shields.io/github/actions/workflow/status/irpedro/ICF/dbt-docs.yml?label=Docs%20dbt&logo=github&logoColor=white)](https://irpedro.github.io/ICF/)
[![Release Automática](https://img.shields.io/github/actions/workflow/status/irpedro/ICF/auto-release.yml?label=Release&logo=github&logoColor=white)](https://github.com/irpedro/ICF/releases/latest) 

Este projeto de IoT e Engenharia de Dados realiza o monitoramento autônomo do clima, umidade do ar, umidade do solo e luminosidade, transmitindo os dados diretamente para um Data Lake na nuvem (Supabase/PostgreSQL) via API REST. O projeto adota a **Arquitetura Medalhão (Bronze, Silver, Gold)** e o paradigma **ELT (Extract, Load, Transform)** para garantir a qualidade, rastreabilidade e segurança dos dados.

## ⚙️ Ferramentas

![MicroPython](https://img.shields.io/badge/MicroPython-1A1A1A?style=for-the-badge&logo=python&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-1A1A1A?style=for-the-badge&logo=supabase&logoColor=3ECF8E)
![dbt](https://img.shields.io/badge/dbt-1A1A1A?style=for-the-badge&logo=dbt&logoColor=FF694B)
![Power BI](https://img.shields.io/badge/Power_BI-1A1A1A?style=for-the-badge&logo=powerbi&logoColor=F2C811)
![Make.com](https://img.shields.io/badge/Make.com-1A1A1A?style=for-the-badge&logo=Make&logoColor=FF1692)

## 📊 Dashboard Interativo (Power BI)
*Interaja com o relatório ao vivo abaixo. Utilize as setas no rodapé do painel para navegar entre as visões de Tempo Real, Resumo Tático (7 Dias) e Visão Estratégica Mensal.*

🔗 **[Clique aqui para abrir o Dashboard em tela cheia em uma nova aba](https://app.powerbi.com/view?r=eyJrIjoiOGE3NzM3YWQtZGVhMC00OTc4LTliOTEtMTU5MDE3ZTk1MjgyIiwidCI6IjdlOTNlMjg2LWIyOWEtNDQ1NC1hNDFhLWU4NDE5ZWM5ZGViNSJ9&pageName=fdfbc4c6a69c2e7bc151)**

<a href="https://app.powerbi.com/view?r=eyJrIjoiOGE3NzM3YWQtZGVhMC00OTc4LTliOTEtMTU5MDE3ZTk1MjgyIiwidCI6IjdlOTNlMjg2LWIyOWEtNDQ1NC1hNDFhLWU4NDE5ZWM5ZGViNSJ9&pageName=fdfbc4c6a69c2e7bc151" target="_blank">
  <img src="dashboard_preview.png" alt="Preview do Dashboard Interativo" width="100%">
</a>

## 🛠️ Guia de Uso e Reprodução

Para instruções detalhadas sobre o uso do projeto, juntamente a montagem do hardware, configuração do ambiente dbt (profiles), criação das tabelas no Supabase e o manual de operação para troca de plantas, acesse o documento completo:

👉 **[Manual de Uso e Configuração](./docs/manual_de_uso.md)**

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

* `/ingestao_perenual.py` e `/plantas.json`: Script de extração responsável por buscar os metadados **RESERVAS** de plantas pela API do Perenual.

* `/plant_sensor_dbt/`: Repositório de transformação de dados contendo as models em SQL (Silver/Gold) e o dicionário de dados **PRINCIPAL** (Seeds).

* `/poc/`: Provas de conceito e testes isolados de hardware.

* `/assets/`: Documentação visual do projeto.

* `/docs/`: Arquivos de bibliografia e de lições aprendidas do projeto.

* `/secrets_example.py`: Arquivo de configurações das APIs do projeto (necessário renomear para somente `secrets.py`).

## 🧪 Qualidade de Dados e Governança (dbt)
> ⚙️ **CI/CD Integrado:** Toda a esteira de governança deste projeto roda de forma automatizada na nuvem através do **GitHub Actions**.

* **Testes Automatizados (dbt test):** Validação rigorosa de integridade dos dados (chaves primárias, valores nulos e integridade referencial) configurada nos contratos do `schema.yml` para garantir que nenhuma anomalia quebre o painel.

* **Documentação e Linhagem (DAG):** Dicionário de dados mapeado desde a origem (Bronze) até ao produto final (Gold). 

  * 🔗 **[Clique aqui para acessar o Dicionário de Dados Interativo (dbt docs)](https://irpedro.github.io/ICF/)** (Gerado e hospedado automaticamente pela esteira do GitHub Actions).

## 📚 Documentação Adicional e Artigos

O sucesso técnico deste projeto exigiu profunda pesquisa em agronomia e resolução de bugs complexos. Para entender os "porquês" das decisões arquiteturais, consulte os documentos abaixo:

* [**Diário de Bordo e Lições Aprendidas**](./docs/licoes_aprendidas.md): Um "Post-Mortem" detalhado com todos os bugs de hardware, problemas de fuso horário, limites do Power BI e como contornei cada desafio.

* [**Bibliografia Científica**](./docs/bibliografia.md): Referências acadêmicas sobre constante dielétrica, lençol freático em vasos e conversão de luz (Lux para PPFD) que embasaram o código.

## 📐 Calibração e Regras de Negócio (Camada Gold)

Alguns dos sensores retornam valores brutos. Para gerar métricas amigáveis e *insights* acionáveis, aplicamos as seguintes transformações:

1. **Umidade do Solo: O Abismo entre IoT e Agronomia (VWC vs. Tensão)**
  Durante o desenvolvimento, foi identificado um grave "Impedance Mismatch" entre as recomendações de fábrica do hardware e a biologia real da planta. O sensor não mede "água" diretamente, mas sim a **Constante Dielétrica ($\kappa$)** do meio.

    * **O Chão Absoluto (Ar = 0%):** O ar possui $\kappa \approx 1$ e os minerais secos do solo possuem um $\kappa$ muito baixo (entre 3 e 5). Como a terra esturricada é basicamente uma mistura de ar e minerais, a sua constante dielétrica resultante é insignificante se comparada à da água ($\kappa \approx 80$). Por isso, cravamos a calibração de **3050 ADC (Ar)** como o nosso "zero absoluto" (solo hidrofóbico e estresse hídrico total). É uma referência universal imutável.
   
    * **A Ilusão da Água Pura (O Teto Relativo):** A água pura possui uma constante elétrica altíssima ($\kappa \approx 80$). A calibração padrão de mercado (água pura = 100%) "esmaga" a escala de leitura. Na escala científica VWC (*Conteúdo Volumétrico de Água*), a terra atinge saturação máxima ("lama") com cerca de 45% de volume de água (que possui um $\kappa$ muito menor que a água pura). Calibrar o limite na água pura tornava metade da capacidade analítica do gráfico inútil.
   
    * **Volume vs. Força (O Ponto Cego do Sensor):** Artigos de agricultura profissional alertam que sensores capacitivos medem apenas o *Volume* de água (VWC - Volumetric Water Content). No entanto, a planta sobrevive baseada no *Potencial Matricial* (a força necessária para sugar a água do solo ou Tensão da Água no Solo). Por exemplo, 30% de água numa terra arenosa é fácil de absorver, mas 30% de água numa argila densa mata a planta de sede, pois a argila "prende" as moléculas de água. O nosso hardware IoT de baixo custo não tem capacidade física para ler essa força.
   
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

## 🤖 Automação, Alertas e Chatbot (Make.com + Telegram)

Para fechar o ciclo de dados (do hardware até a palma da mão), foi implementada uma camada de orquestração rodando 100% na nuvem utilizando o **Make.com**. A arquitetura possui duas frentes distintas: um pipeline de agendamento (*Scheduled Multiplexer*) e um aplicativo de mensagens bidirecional (*Webhook Router*).

### 1. Rotinas Agendadas (Scheduled Multiplexer)
O fluxo autônomo é ativado a cada 6 horas e consome diretamente a Camada Gold do dbt (Supabase), ramificando-se em três rotas analíticas:

* **Rota A (Observabilidade de Hardware):** Verifica a saúde da infraestrutura calculando o `minutos_offline` (Timestamp do Servidor vs. Último envio do ESP32). Dispara alertas críticos se a placa perder conexão Wi-Fi ou bateria.

* **Rota B (Prevenção e Saúde da Planta):** Monitoriza regras de negócio críticas, como "Solo Seco" ou "Encharcado". Possui um sistema integrado de *Cooldown* (usando Make Data Stores) que bloqueia envios repetidos por 12 horas, atuando como um filtro Anti-Spam.

* **Rota C (Fechamento do Dia):** Protegida por um filtro de *Timezone* que só abre a catraca às 20h. Avalia as agregações do dbt (tabela diária) enviando um boletim completo com:

    * Médias, Máximas e Mínimas do dia (Temperatura e Umidade).
    * *Daily Light Integral* (Horas de Sol Útil e Diagnóstico de Saúde Luminosa).
    * Uptime real do sistema (% de confiabilidade dos dados do dia).

### 2. Interface Interativa (Chatbot Bidirecional)
O Telegram não atua apenas como um receptor de alertas, mas como uma interface de usuário completa. Configurado via *BotFather* e um Webhook permanente no Make.com, o sistema escuta o usuário 24/7 e responde a comandos instantâneos:

* **Menu Interativo:** Ao acionar os botões do bot (ex: `/status` ou `/plantas`), o Make.com processa a requisição, realiza uma query *on-the-fly* no banco de dados e retorna o status em tempo real da planta, sem a necessidade de abrir o dashboard no computador.

* **Acesso Rápido:** O comando `/links` centraliza o acesso fácil ao Power BI Mobile, repositório e documentações.

> 💡 **Nota de Reprodutibilidade:** Os cenários do Make.com e o Bot do Telegram possuem chaves de API privadas (Hardcoded Tokens) e não estão diretamente disponíveis no repositório. Para replicar este projeto, será necessário configurar o seu próprio *bot* via BotFather e conectar os webhooks da sua conta Make ao seu banco de dados PostgreSQL. Para conferir a estrutura visual dos cenários, consulte a pasta `/assets/visual`.

## 🚀 Visão de Futuro e Escalabilidade

O projeto foi desenhado seguindo princípios de arquitetura modular, permitindo a sua evolução de uma ferramenta de monitorização pessoal para uma plataforma escalável (SaaS). Caso a implementação, as próximas etapas de desenvolvimento seriam:

### 1. Desacoplamento e Multi-tenancy
Atualmente, as notificações estão configuradas para um unico utilizador administrativo. A evolução prevê a criação de uma camada de gestão de utilizadores no PostgreSQL, onde cada sensor é vinculado a um `id_utilizador` de uma nova tabela de usuários.

- **Notificações Dinâmicas:** O motor de regras no Make.com passará a consultar o `telegram_chat_id` diretamente da base de dados, permitindo que o sistema suporte múltiplos utilizadores em simultâneo.

### 2. Interface de Utilizador (Portal de Gestão)
Para eliminar a necessidade de configuração via SQL por parte do utilizador, está prevista a criação de um Front-end unificado.
- **Provisionamento Self-service:** Interface para registo de novos sensores e mapeamento de espécies botânicas.

- **Dashboards Dinâmicos:** Integração com Power BI através de filtragem dinâmica de parâmetros, permitindo que o utilizador visualize os dados específicos de cada sensor de forma isolada num único ambiente centralizado.
