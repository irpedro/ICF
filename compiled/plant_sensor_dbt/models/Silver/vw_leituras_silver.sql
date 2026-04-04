

SELECT 
    id,
    -- Converte o horário para SP e salva como timestamp limpo (sem fuso)
    data_ingestao AT TIME ZONE 'America/Sao_Paulo' AS data_leitura_sp,
    
    -- Extrai as chaves do JSON e já converte para o tipo correto (Número)
    (dados_json->>'temperature_c')::NUMERIC AS temperatura_c,
    (dados_json->>'humidity_pct')::NUMERIC AS umidade_ar_pct,
    (dados_json->>'soil_moisture_raw')::INT AS umidade_solo_raw,
    (dados_json->>'light_intensity_raw')::NUMERIC AS luz_raw,
    
    arquivo_origem AS dispositivo
FROM 
    "postgres"."public"."leituras_brutas_bronze"