# 📖 Diário de Bordo e Lições Aprendidas (Post-Mortem)

Este projeto foi construído do zero absoluto e exigiu o aprendizado, a seleção e a integração de tecnologias que cruzam quase todas as áreas da Engenharia de Computação e Dados. Abaixo estão registrados os maiores desafios enfrentados, os "becos sem saída" e as decisões arquiteturais tomadas para superá-los. 

## 1. Business Intelligence e Analytics (O "Boss Final" do Power BI)
* **A Batalha do SSL (AWS vs. Microsoft):** Este foi sem dúvida o maior obstáculo técnico do projeto. A conexão direta entre o Power BI Service (Nuvem) e o banco PostgreSQL no Supabase (hospedado na AWS) falhava por problemas de certificação e criptografia. Tivemos que recuar para o Power BI Desktop, reconfigurar toda a cadeia de conexão no Editor Avançado (Power Query) forçando os parâmetros de criptografia via API so Supabase. Tudo para apenas conseguir publicar o dashboard na nuvem de forma acessível para outros usuários.

* **Performance e DAX Dinâmico:** A Microsoft limita severamente o poder de processamento de dashboards em contas gratuitas/padrão. Para otimizar, criamos colunas DAX focadas em filtros. Porém, durante a homologação, descobrimos que esses filtros não operavam de forma dinâmica quando o usuário trocava de planta no seletor. Isso nos obrigou a refatorar as medidas DAX para garantir que o contexto de filtro respeitasse o ciclo de vida (SCD2) de cada vaso individualmente.

## 2. Engenharia e Arquitetura de Dados (Supabase & dbt)
* **O Desafio da Escalabilidade:** O que começou como a leitura de um único sensor escalou para um sistema dinâmico. Tivemos que reformular profundamente as tabelas Gold, o código dbt, o Power BI e o seletor de plantas, criando novas colunas e chaves (como o `ID_DO_SENSOR`) para garantir que o sistema pudesse adotar infinitos vasos no futuro (inclusive todos os tipos de casos) sem quebrar o código anterior.

* **A Falha da API Perenual:** A ideia original era buscar as necessidades botânicas via API (`ingestao_perenual.py`). Na prática, os dados vinham extremamente incompletos e ruidosos. **O Pivot:** Abandonamos a automação falha, descartamos o uso do arquivo (incluindo o arquivo `plantas.json`) como fonte de dados principal para secundária, e assumimos o controle da qualidade da dados com a criação manual de uma "semente de ouro" (`limites_plantas_cientifico.csv`) rigorosamente curada a partir de dados botânicos científicos.

* **A Lógica de Fallback (Hierarquia de Confiança):** Para garantir que o painel nunca ficasse vazio ou quebrasse por falta de dados botânicos, aprendemos a implementar o padrão de *Fallback* no SQL utilizando a função `COALESCE`. A arquitetura tenta priorizar primeiro os dados científicos oficiais (`limites_plantas_cientifico.csv`) e, apenas em caso de falha ou planta não mapeada, recorre aos dados automatizados da API.

* **Cálculo de DLI com CTEs Avançadas:** Monitorar a luz não era apenas calcular uma média simples. Foi um desafio técnico utilizar *Common Table Expressions (CTEs)* complexas na Camada Gold Diária para transformar medições pontuais de *Lux* em Radiação Fotossinteticamente Ativa (PPFD) e somar tudo isso de forma correta ao longo do dia para gerar a métrica real de *Daily Light Integral (DLI)*.

* **Granularidade das Tabelas Gold:** Os dados de Luz e Ambiente (Ar) operavam em uma frequência/importância diferente dos dados do Solo (Umidade da terra) e os dados do clima (temperatura e umidado do ar). Para não corromper as análises, arquitetamos a divisão da Camada Gold em duas tabelas/fatos distintas uma granulada e outra agregada.

* **O Caos da Física no SQL (Travamento de Limites):** Sensores físicos geram flutuações. Percebemos que, se o sensor lesse um valor marginalmente fora da calibração (mais seco que o ar ou mais molhado que a lama), a nossa regra de três gerava percentuais impossíveis (como -5% ou 105%). Resolvemos isso implementando as funções matemáticas de contenção `GREATEST(0, LEAST(100, ...))` diretamente na Camada Gold, garantindo a integridade visual no Power BI.

* **O Caos do IPv6 no Supabase:** O Supabase forçou a transição de seus bancos de dados para IPv6, quebrando conexões de ferramentas que só operavam em IPv4 (como o Power BI e o Make). Tivemos que descobrir e reconfigurar a conexão para usar o *Connection Pooler* (PgBouncer/Supavisor) em IPv4.

* **Retenção de Histórico:** Foram enfrentandos debates arquiteturais longos sobre manter o histórico completo das plantas (SCD2) versus criar rotinas de exclusão de dados antigos para poupar armazenamento na nuvem.

* **A Matemática do SCD Tipo 2 (A Data Infinita):** Para garantir que a junção temporal entre a leitura física do sensor e o cadastro do vaso funcionasse de forma contínua, aprendemos a utilizar o padrão de "Data do Fim dos Tempos" (`2099-12-31 23:59:59`) para os registros ativos. Isso blindou a lógica de *Range JOIN* (data de leitura *BETWEEN* data de início e data de fim) no cruzamento da Camada Gold.

* **Versionamento (O problema das Dependências):** Logo no início da estruturação do Data Lake, enfrentamos quebras severas de compatibilidade entre a versão local do Python instalada na máquina e as exigências mais recentes da biblioteca do dbt-core.

* **A Guerra dos Fusos Horários (UTC vs Local):** O Supabase, o Power BI Service e o Make.com rodam nativamente no fuso horário UTC (Inglaterra). Isso fazia com que o nosso "Fechamento do Dia" no Telegram e as datas no Power BI virassem o dia às 21h do Brasil. Para resolver isso, centralizamos a conversão temporal (`AT TIME ZONE 'America/Sao_Paulo'`) de forma rígida na Camada Silver do dbt.

## 3. Hardware, IoT e Física (ESP32 e Arduino)
* **A Curva de Aprendizado (MicroPython):** Houve um esforço para aprender do zero a linguagem Micropython do Arduino e os conceitos de eletrônica. Para tal foram criados diversos arquivos `poc_` (Proof of Concept) para testar a tela OLED, o módulo Wi-Fi e cada sensor isoladamente antes de juntar tudo no `main.py`.

* **Observabilidade na Borda (Display OLED I2C):** Durante os primeiros testes, quando um dado não chegava à nuvem, era impossível saber se a falha era no Wi-Fi, na leitura elétrica ou no banco de dados. Implementamos a programação de um Display OLED (`ssd1306`) operando via barramento I2C para imprimir os estados (`"A enviar"`, `"OK!"`, `"Erro DB"`). Isso transformou um hardware "cego" numa ferramenta auto-explicativa, acelerando extremamente o debug.

* **O Bug Silencioso do Wi-Fi:** Enfrentamos um problema onde o ESP32 não comunicava direito por causa do tipo do Wi-Fi. Levamos muito tempo para debugar e descobrir que o problema físico estava no roteador/placa de rede do notebook, que era excessivamente devagar para o ESP32.

* **Serendipidade Eletrônica (Chip NE555):** Descobrimos através de vídeos na internet que o nosso sensor capacitivo v1.2 possuía um defeito crônico de fabricação (chip timer NE555 no lugar do TLC555). Entretanto, a calibração manual e a regra de três matemática que havíamos criado na Camada Gold mitigaram essa falha de hardware sem que soubéssemos no início.

* **Segurança na Borda:** A necessidade de esconder senhas do Wi-Fi e chaves de API da internet nos forçou a entender sobre segurança e implementar o `secrets.py` atrelado ao `.gitignore`.

* **Amnésia do Deepsleep e Consumo de Energia:** Para garantir que a placa e economizasse energia (para futuramente poder ser ligada em uma bateria com placa solar), implementamos o `machine.deepsleep()`. O grande problema é que o ESP32 perde todo o estado da memória RAM ao dormir. Tivemos que estruturar o código para que ele refizesse a conexão Wi-Fi do zero a cada ciclo sem falhar.

* **O Tempo de "Warm-up" dos Sensores:** Ao acordar do deepsleep, o ESP32 tentava ler o DHT22 e o sensor de luz (BH1750) na velocidade da luz. Como os componentes físicos demoram milissegundos para energizar, o código quebrava ou enviava dados nulos. Tivemos que implementar pausas estratégicas (`time.sleep`) logo após o boot para os sensores "esquentarem" antes da leitura.

## 4. Orquestração, DevOps e CI/CD
* **A Evolução para um Chatbot Interativo:** O sistema começou como um "pombo-correio" de mão única para enviar alertas. O desafio foi transformá-lo numa aplicação bidirecional. Tivemos que configurar comandos nativos no Telegram (via *BotFather*) e criar um *Webhook/Router* no Make.com que ficasse escutando o usuário. Isso permitiu que o sistema respondesse de forma dinâmica a comandos como `/status` ou `/links`.

* **Monitoramento de Infraestrutura (Heartbeat):** Como saber se a placa na varanda ficou sem bateria, se perdeu o Wi-Fi ou em caso de problema de hardware sem ter que olhar para ela? Implementamos uma lógica de *Heartbeat* (pulsação) na nuvem. Criamos uma query que compara o horário atual do servidor com o *timestamp* da última leitura recebida na tabela Bronze. Se a diferença passar de 2 horas, o sistema entende que o hardware "morreu" e dispara um alerta de infraestrutura automaticamente.

* **As Limitações do Make.com:** A versão gratuita do Make provou-se altamente restritiva. Tivemos dificuldade na configuração visual e fomos forçados a refatorar o fluxo para fundir todos os tipos de alerta em um único caminho (*blueprint*) para não estourar a cota de execuções.

* **Qualidade Automatizada:** Tivemos o zelo de documentar todos os testes de qualidade, de chave primária e chaves estrangeiras no arquivo `schema.yml` do dbt, juntamente a documentação automática do dbt, amarrando isso em uma esteira de CI/CD no **GitHub Actions** para rodar na nuvem.

* **A Formatação do Payload HTTP:** O envio do JSON do MicroPython para a API REST do Supabase gerou erros de `Bad Request` (400) no início. Tivemos que alinhar a formatação correta de dicionários no Python com a estrutura exigida pela coluna `JSONB` do PostgreSQL.

## 5. Gestão de Produto, Documentação e Ciência
* **Pivot de SaaS para Open-Source:** No meio do projeto, chegamos a desenhar a arquitetura para transformar isso em um SaaS (Software as a Service) multi-inquilino. Contudo, decidimos recuar e focar na excelência técnica de um projeto simples, focado no usuário final (Hobbista/Maker), mantendo a arquitetura limpa.

* **O Peso da Documentação Científica:** A compilação do arquivo `bibliografia.md` foi **extremamente** importante. O cruzamento das pesquisas reais de Agronomia, Botânica e Física (Constante Dielétrica, Lençol Freático Suspenso em Vasos, Conversão de Lux para PPFD) foi o que deu base científica para todas as lógicas de banco de dados aplicadas.

* **Manutenção do Conhecimento:** O esforço constante de reescrever o `README.md` a cada mudança de rota provou-se vital. Além disso, criamos um repositório visual documentando as instalações e testes na pasta `assets`.