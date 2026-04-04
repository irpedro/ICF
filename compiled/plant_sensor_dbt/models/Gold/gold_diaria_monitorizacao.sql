

-- Esta consulta tem como objetivo criar uma visão diária de monitoramento das condições ambientais para as plantas, com foco na saúde luminosa.
-- Ela agrega as leituras de temperatura, umidade e luz, calcula o tempo de exposição à luz e escuridão, e compara com as metas definidas para cada planta, 
-- além de avaliar a cobertura dos dados para garantir análises confiáveis.
WITH leituras_com_lag AS (
    SELECT 
        l.data_leitura_sp,
        DATE(l.data_leitura_sp) AS data_ref,
        l.temperatura_c,
        l.umidade_ar_pct,
        l.luz_raw AS luz_lux,
        (l.luz_raw * 0.0185) AS luz_par_ppfd, -- Conversão aproximada de lux para PPFD, da luz visível par a luz que as plantas usam para fotossíntese
        p.lux_min,
        p.horas_luz_minimas,
        p.horas_descanso_minimas,
        ((3050 - l.umidade_solo_raw) / (3050 - 600.0)) * 100 AS umidade_solo_pct,
        
        -- Calcula o intervalo bruto em minutos desde a última leitura
        EXTRACT(EPOCH FROM (l.data_leitura_sp - LAG(l.data_leitura_sp) OVER (PARTITION BY DATE(l.data_leitura_sp) ORDER BY l.data_leitura_sp))) / 60.0 AS delta_minutos

    FROM "postgres"."public"."vw_leituras_silver" l
    JOIN "postgres"."public"."cadastro_sensores" c ON l.dispositivo = c.dispositivo
    JOIN "postgres"."public"."limites_plantas_cientifico" p ON c.nome_planta = p.nome_popular
),

-- Enriquecemos as leituras com o tratamento de gaps para garantir que períodos sem dados não distorçam as análises diárias
leituras_enriquecidas AS (
    SELECT 
        *,
        -- 🛡️ TRATAMENTO DE GAPS (BURACOS DE TEMPO)
        CASE 
            WHEN delta_minutos IS NULL THEN 15.0 -- Primeira leitura do dia assumimos 15 minutos de monitoramento antes da leitura
            WHEN delta_minutos > 60.0 THEN 15.0  -- Sensor ficou offline e voltou, não contamos as horas perdidas
            ELSE delta_minutos                   -- Funcionamento normal contínuo
        END AS minutos_desde_ultima_leitura
    FROM leituras_com_lag
),

-- Agregamos as leituras por dia para calcular as médias e totais diários, além de comparar com as metas de luz e descanso
agregacao_diaria AS (
    SELECT 
        data_ref,
        AVG(temperatura_c) AS temp_media,
        AVG(umidade_ar_pct) AS umid_media,
        AVG(luz_par_ppfd) AS par_ppfd_medio,
        
        SUM(minutos_desde_ultima_leitura) AS total_minutos_monitorados,
        AVG(umidade_solo_pct) AS umid_solo_media,

        -- Calculamos o tempo total de exposição à luz e escuridão com base no limiar de 50 lux dividindo o dia em períodos de luz e escuridão
        SUM(CASE WHEN luz_lux >= 50 THEN minutos_desde_ultima_leitura ELSE 0 END) / 60.0 AS horas_sol_util,
        SUM(CASE WHEN luz_lux < 50 THEN minutos_desde_ultima_leitura ELSE 0 END) / 60.0 AS horas_escuridao,
        
        MAX(horas_luz_minimas) AS meta_luz,
        MAX(horas_descanso_minimas) AS meta_descanso
    FROM leituras_enriquecidas
    GROUP BY data_ref
)

-- Na tabela final, calculamos a taxa de cobertura dos dados e aplicamos as regras de alerta para saúde luminosa
SELECT 
    data_ref,
    ROUND(temp_media, 1) AS temperatura_media_c,
    ROUND(umid_media, 1) AS umidade_media_pct,
    ROUND(par_ppfd_medio, 2) AS par_ppfd_medio,
    ROUND(horas_sol_util, 2) AS horas_sol_util_diarias,
    ROUND(horas_escuridao, 2) AS horas_descanso_diarias,
    ROUND(umid_solo_media, 1) AS umidade_solo_media_pct,
    
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