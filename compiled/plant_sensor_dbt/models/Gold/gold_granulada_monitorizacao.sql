

WITH leituras AS (
    SELECT * FROM "postgres"."public"."vw_leituras_silver"
),

-- Nova CTE puxando o nosso Seed (A Tabela de De/Para)
cadastro_sensores AS (
    SELECT * FROM "postgres"."public"."cadastro_sensores"
),

limites_cientificos AS (
    SELECT * FROM "postgres"."public"."limites_plantas_cientifico"
),

-- Na CTE de cruzamento, juntamos as leituras com o cadastro de sensores para descobrir qual planta está sendo monitorizada, 
--e depois juntamos com os limites científicos para obter as metas de temperatura, umidade e luz para cada planta.
cruzamento AS (
    SELECT 
        l.id,
        l.data_leitura_sp,
        l.temperatura_c,
        l.umidade_ar_pct,    
        l.umidade_solo_raw,

        -- Regra de três invertida: 3050 (0%) a 600 (100%)
        -- Usamos GREATEST e LEAST para travar o valor entre 0 e 100 (evitar -5% ou 110%)
        GREATEST(0, LEAST(100, ROUND(((3050 - l.umidade_solo_raw) / (3050 - 600.0)) * 100, 1))) AS umidade_solo_pct,

        -- A luz instantânea para o gráfico de linhas do Power BI
        l.luz_raw,
        ROUND((l.luz_raw * 0.0185), 2) AS luz_par_ppfd,

        c.nome_popular AS planta_monitorizada,
        c.nome_cientifico,
        c.temp_min_c,
        c.temp_max_c,
        c.umid_ar_min_pct,
        c.umid_ar_max_pct,
        c.tolerancia_seca,
        TRUE AS flg_origem_dados_confiavel 
    FROM leituras l
    
    -- 1º JOIN: Descobre a planta com base no MAC Address / Dispositivo
    LEFT JOIN cadastro_sensores cs 
        ON l.dispositivo = cs.dispositivo
        
    -- 2º JOIN: Busca os limites biológicos da planta que acabamos de descobrir
    LEFT JOIN limites_cientificos c 
        ON cs.nome_planta = c.nome_popular
)

-- Na tabela final, aplicamos as regras de alerta para cada parâmetro ambiental, comparando as leituras com os limites científicos para cada planta monitorizada.
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
        WHEN tolerancia_seca = 'ALTA'  AND umidade_solo_pct <= 20 THEN 'ALERTA: Solo Seco (Regar)'
        WHEN tolerancia_seca = 'MEDIA' AND umidade_solo_pct <= 40 THEN 'ALERTA: Solo Seco (Regar)'
        WHEN tolerancia_seca = 'BAIXA' AND umidade_solo_pct <= 60 THEN 'ALERTA: Solo Seco (Regar)'
        ELSE 'Umidade do Solo Adequada'
    END AS status_umidade_solo

FROM cruzamento