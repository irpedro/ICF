{{ config(materialized='view') }}

WITH leituras_com_lag AS (
    SELECT 
        l.data_leitura_sp,
        DATE(l.data_leitura_sp) AS data_ref,
        l.temperatura_c,
        l.umidade_ar_pct,
        l.luz_raw AS luz_lux,
        (l.luz_raw * 0.0185) AS luz_par_ppfd,
        p.lux_min,
        p.horas_luz_minimas,
        p.horas_descanso_minimas,
        
        -- Calcula o intervalo bruto em minutos desde a última leitura
        EXTRACT(EPOCH FROM (l.data_leitura_sp - LAG(l.data_leitura_sp) OVER (PARTITION BY DATE(l.data_leitura_sp) ORDER BY l.data_leitura_sp))) / 60.0 AS delta_minutos

    FROM {{ ref('vw_leituras_silver') }} l
    JOIN {{ ref('cadastro_sensores') }} c ON l.dispositivo = c.dispositivo
    JOIN {{ ref('limites_plantas_cientifico') }} p ON c.nome_planta = p.nome_popular
),

leituras_enriquecidas AS (
    SELECT 
        *,
        -- 🛡️ TRATAMENTO DE GAPS (BURACOS DE TEMPO)
        CASE 
            WHEN delta_minutos IS NULL THEN 15.0 -- Primeira leitura do dia
            WHEN delta_minutos > 60.0 THEN 15.0  -- Sensor ficou offline e voltou, não contamos as horas perdidas
            ELSE delta_minutos                   -- Funcionamento normal contínuo
        END AS minutos_desde_ultima_leitura
    FROM leituras_com_lag
),

agregacao_diaria AS (
    SELECT 
        data_ref,
        AVG(temperatura_c) AS temp_media,
        AVG(umidade_ar_pct) AS umid_media,
        AVG(luz_par_ppfd) AS par_ppfd_medio,
        
        SUM(minutos_desde_ultima_leitura) AS total_minutos_monitorados,
        
        SUM(CASE WHEN luz_lux >= lux_min THEN minutos_desde_ultima_leitura ELSE 0 END) / 60.0 AS horas_sol_util,
        SUM(CASE WHEN luz_lux < 50 THEN minutos_desde_ultima_leitura ELSE 0 END) / 60.0 AS horas_escuridao,
        
        MAX(horas_luz_minimas) AS meta_luz,
        MAX(horas_descanso_minimas) AS meta_descanso
    FROM leituras_enriquecidas
    GROUP BY data_ref
)

SELECT 
    data_ref,
    ROUND(temp_media, 1) AS temperatura_media_c,
    ROUND(umid_media, 1) AS umidade_media_pct,
    ROUND(par_ppfd_medio, 2) AS par_ppfd_medio,
    ROUND(horas_sol_util, 2) AS horas_sol_util_diarias,
    ROUND(horas_escuridao, 2) AS horas_descanso_diarias,
    
    -- Limitamos a 100% para evitar flutuações decimais (ex: 100.3%)
    LEAST(ROUND((total_minutos_monitorados / 1440.0) * 100, 1), 100.0) AS taxa_cobertura_dados_pct,
    
    CASE 
        WHEN (total_minutos_monitorados / 1440.0) < 0.70 THEN 'ALERTA: Dados Insuficientes (< 70% Uptime)'
        WHEN horas_sol_util < meta_luz THEN 'ALERTA: Déficit de Luz'
        WHEN horas_escuridao < meta_descanso THEN 'ALERTA: Stress Luminoso (Falta Descanso)'
        ELSE 'Luminosidade e Fotoperíodo Adequados'
    END AS status_saude_luminosa

FROM agregacao_diaria
ORDER BY data_ref DESC