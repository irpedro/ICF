# 📚 Referências Científicas e Tecnológicas

As regras de negócio e a arquitetura de dados aplicadas neste projeto não são arbitrárias. Elas foram fundamentadas em literatura científica (agronomia/física) e nos padrões da indústria de Engenharia de Software.

## 1. Tolerância à Seca e Sobrevivência Indoor
Referência para a classificação da capacidade de sobrevivência das espécies ornamentais (ex: Aloe Vera e Samambaia) e determinação dos níveis de estresse hídrico.

* LORENZI, Harri. **Plantas Ornamentais no Brasil: arbustivas, herbáceas e trepadeiras**. 4. ed. Nova Odessa, SP: Instituto Plantarum, 2008.

## 2. Fotoperíodo e Exigência Luminosa (Lux para PPFD)
Estudos e fórmulas utilizadas para basear as regras de horas mínimas de sol e a conversão matemática da iluminância visual (Lux) para a Radiação Fotossinteticamente Ativa (PPFD/PAR) utilizada na Camada Gold.

* [OLIVEIRA, J. E. de. **Crescimento e anatomia de 'Begonia Megawatt' cultivadas sob diferentes telas de sombreamento**. Tese (Doutorado) - ESALQ/USP, Piracicaba, 2023](https://repositorio.usp.br/item/003153870).

* [ALVES, M. de C. **Avaliação de malhas fotosseletivas no cultivo protegido de plantas ornamentais**. Tese (Doutorado) - ESALQ/USP, Piracicaba, 2025.](https://www.teses.usp.br/teses/disponiveis/11/11136/tde-18092025-112722/es.php)

* **Fator de Conversão Matemática:** THIMIJAN, R. W.; HEINS, R. D. **Photometric, radiometric, and quantum light units of measure: A review of procedures for interconversion**. *HortScience*, 18(6), 818-822, 1983. *(Fonte da constante de aproximação onde 1 µmol/m²/s de luz natural ≈ 54 Lux).*

## 3. Climatologia: Temperatura e Umidade do Ar (DHT22)
Parâmetros de controle utilizados para definir as *flags* de alerta de "Estresse Térmico" e "Ar Seco" nas leituras do sensor ambiente (DHT22).

* EMPRESA BRASILEIRA DE PESQUISA AGROPECUÁRIA (EMBRAPA). Manuais técnicos e circulares sobre ambiência e estresse térmico no cultivo protegido.

## 4. Calibração de Sensores Capacitivos de Solo (IoT)
Justificativa para o "Pivot de Engenharia", abandonando a calibração do sensor em água pura em favor da saturação do próprio solo (Capacidade de Campo).

* **Padrão de Mercado/Hobby:** [DFRobot. Gravity: Analog Capacitive Soil Moisture Sensor - Product Wiki](https://wiki.dfrobot.com/Capacitive_Soil_Moisture_Sensor_SKU_SEN0193). 

* **Padrão Agronômico:** [SCHWAMBACK, D., et al. Automated Low-Cost Soil Moisture Sensors: Trade-Off between Cost and Accuracy. *Sensors* (MDPI), 2023](https://www.mdpi.com/1424-8220/23/5/2451). Estudo que fundamenta a necessidade de calibrar o limite de 100% saturando a amostra do próprio solo, garantindo precisão biológica no Data Lake.

## 5. Modelagem e Arquitetura de Dados
Fundamentação teórica para as transformações em SQL (dbt) e rastreabilidade temporal.

* **Arquitetura Medalhão (Bronze/Silver/Gold):** DATABRICKS. *What is a Medallion Architecture?* Padrão da indústria para organização lógica e qualidade em Data Lakes.

* **Slowly Changing Dimensions (SCD Tipo 2):** KIMBALL, Ralph; ROSS, Margy. **The Data Warehouse Toolkit: The Definitive Guide to Dimensional Modeling**. 3. ed. Wiley, 2013. *(Fundamentação para a rastreabilidade histórica das trocas de vasos no dbt).*

## 6. Física de Fluidos em Substratos e Inserção de Hardware (IoT)
Fundamentação teórica para o diagnóstico e solução do "Lençol Freático Suspenso" e melhores práticas de *placement* de sensores capacitivos para evitar falsos positivos de saturação.

* **Fenômeno Físico (Perched Water Table):** * [Container Soils are Different (Oregon State University Extension)](https://agsci.oregonstate.edu/sites/agscid7/files/horticulture/osu-nursery-greenhouse-and-christmas-trees/onn010809.pdf) - Estudo demonstrando que a tensão capilar impede a drenagem completa da gravidade, formando uma zona permanente de saturação nos últimos centímetros do fundo de recipientes.

  * [Gardening in Raised Beds and Containers (South Dakota State University Extension)](https://extension.sdstate.edu/sites/default/files/2024-07/P-00301.pdf) - Confirma a criação inevitável da "zona anaeróbica" no fundo de vasos pequenos.

* **Boas Práticas de Hardware (Eixo Z e Inserção Diagonal):** * [Capacitive Soil Moisture Calibration with Arduino (Maker Portal)](https://makersportal.com/blog/2020/5/26/capacitive-soil-moisture-calibration-with-arduino) - Guia definitivo sobre como o ar e a densidade da terra afetam o sensor v1.2.

  * [Why most Arduino Soil Moisture Sensors suck (Andreas Spiess / YouTube)](https://www.youtube.com/watch?v=udmJyncDvw0) - Referência clássica na comunidade Maker de IoT demonstrando que a inserção diagonal/oblíqua do hardware é obrigatória para evitar "canais de água" (*Water Channeling*), onde a água da rega escorre direto pelo corpo da placa enganando a leitura.

  * [Reverse Engineering the Capacitive Soil Moisture Sensor (YouTube)](https://www.youtube.com/watch?v=IGP38bz-K48) - Análise profunda e denúncia de defeitos de fabricação em lotes paralelos, especificamente a substituição do chip TLC555 pelo NE555 e a ausência de vias de aterramento (resistor de 1MΩ). O estudo justifica as anomalias elétricas e a compressão da escala de leitura ao operar o sensor em microcontroladores de 3.3V (como o ESP32).