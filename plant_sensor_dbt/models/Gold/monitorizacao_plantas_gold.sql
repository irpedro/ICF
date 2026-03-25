{{ config(materialized='view') }}

WITH leituras AS (
    SELECT * FROM {{ ref('vw_leituras_silver') }}
),

-- Nova CTE puxando o nosso Seed (A Tabela de De/Para)
cadastro_sensores AS (
    SELECT * FROM {{ ref('cadastro_sensores') }}
),

limites_cientificos AS (
    SELECT * FROM {{ ref('limites_plantas_cientifico') }}
),

cruzamento AS (
    SELECT 
        l.id,
        l.data_leitura_sp,
        l.temperatura_c,
        l.umidade_ar_pct,    
        l.umidade_solo_raw,
        -- l.luz_raw,      <-- COMENTADO: Aguardando calibração do hardware
        c.nome_popular AS planta_monitorizada,
        c.nome_cientifico,
        c.temp_min_c,
        c.temp_max_c,
        c.umid_ar_min_pct,
        c.umid_ar_max_pct,
        c.tolerancia_seca,
        -- c.lux_min,           <-- COMENTADO: Aguardando Master Data de luz
        TRUE AS flg_origem_dados_confiavel 
    FROM leituras l
    
    -- 1º JOIN: Descobre a planta com base no MAC Address / Dispositivo
    LEFT JOIN cadastro_sensores cs 
        ON l.dispositivo = cs.dispositivo
        
    -- 2º JOIN: Busca os limites biológicos da planta que acabamos de descobrir
    LEFT JOIN limites_cientificos c 
        ON cs.nome_planta = c.nome_popular
)

SELECT 
    *,
    -- 1. Temperatura
    CASE 
        WHEN temperatura_c < temp_min_c THEN 'ALERTA: Frio extremo'
        WHEN temperatura_c > temp_max_c THEN 'ALERTA: Calor extremo'
        ELSE 'Temperatura Ideal'
    END AS status_temperatura,
    
    -- 2. Umidade do Ar
    CASE 
        WHEN umidade_ar_pct < umid_ar_min_pct THEN 'ALERTA: Ar muito seco'
        WHEN umidade_ar_pct > umid_ar_max_pct THEN 'ALERTA: Ar muito úmido'
        ELSE 'Umidade do Ar Adequada'
    END AS status_umidade_ar,

    -- 3. Umidade do Solo
    CASE 
        WHEN umidade_solo_raw > 3000 THEN 'ALERTA: Solo muito seco (Regar!)' -- (Ajuste os valores para o seu RAW empírico)
        WHEN umidade_solo_raw < 1000 THEN 'ALERTA: Solo encharcado'
        ELSE 'Umidade do Solo Adequada'
    END AS status_umidade_solo

    -- 4. Luminosidade 
    /* <-- Bloco inteiro comentado para uso futuro no Passo 14
    , CASE 
        WHEN luminosidade < lux_min THEN 'ALERTA: Luz insuficiente'
        ELSE 'Luminosidade Adequada'
    END AS status_luminosidade
    */

FROM cruzamento