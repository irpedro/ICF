import requests
import time
import json
import secrets  

# Script de ingestão em lote para popular a tabela dim_plantas no Supabase usando dados da API Perenual que atua como fonte de dados reserva, 
# a partir de uma lista de plantas comuns em um arquivo JSON. 
# O script inclui tratamento de erros, transformação segura dos dados e respeita os limites de taxa da API gratuita (100 por dia).

# --- 1. CREDENCIAIS ---
SUPABASE_URL_COMPLETA = f"{secrets.SUPABASE_URL}/rest/v1/dim_plantas"

HEADERS_SUPABASE = {
    "apikey": secrets.SUPABASE_KEY,
    "Authorization": f"Bearer {secrets.SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

# --- LER A LISTA DE PLANTAS DO ARQUIVO JSON ---
try:
    with open('plantas.json', 'r', encoding='utf-8') as arquivo:
        plantas_comuns = json.load(arquivo)
except FileNotFoundError:
    print("❌ Arquivo plantas.json não encontrado!")
    plantas_comuns = []

print(f"🌱 Iniciando carga em lote para {len(plantas_comuns)} plantas...\n")

for termo_busca in plantas_comuns:
    try:
        # --- 2. EXTRAÇÃO ---
        url_perenual = f"https://perenual.com/api/species-list?key={secrets.PERENUAL_API_KEY}&q={termo_busca}"
        resposta_api = requests.get(url_perenual).json()
        
        if not resposta_api.get('data'):
            print(f"⚠️ {termo_busca}: Não encontrada na API. Pulando...")
            continue

        planta_bruta = resposta_api['data'][0] 
        
        # --- 3. TRANSFORMAÇÃO SEGURA ---
        # Trata o nível de rega
        nivel_rega = planta_bruta.get('watering') or 'Average'
        
        # Trata a lista de luz (se vier null, assume 'Part shade')
        luz_lista = planta_bruta.get('sunlight')
        luz_api = luz_lista[0] if luz_lista else 'Part shade'

        if nivel_rega == "Frequent":
            umidade_min, umidade_max = 60.0, 90.0
        elif nivel_rega == "Minimum":
            umidade_min, umidade_max = 10.0, 40.0
        else: 
            umidade_min, umidade_max = 30.0, 70.0

        # Trata o nome científico
        nome_cientifico_lista = planta_bruta.get('scientific_name')
        nome_cientifico_api = nome_cientifico_lista[0] if nome_cientifico_lista else ''

        planta_tratada = {
            "nome_comum": planta_bruta.get('common_name', termo_busca).title(),
            "nome_cientifico": nome_cientifico_api,
            "humidade_solo_minima_pct": umidade_min,
            "humidade_solo_maxima_pct": umidade_max,
            "luz_ideal": luz_api.title()
        }

        # --- 4. CARGA ---
        resposta_supa = requests.post(SUPABASE_URL_COMPLETA, headers=HEADERS_SUPABASE, json=planta_tratada)

        if resposta_supa.status_code == 201:
            print(f"✅ Sucesso: {planta_tratada['nome_comum']} adicionada!")
        else:
            print(f"❌ Erro no banco ({termo_busca}): {resposta_supa.text}")
            
    except Exception as e:
        print(f"❌ Erro no script ({termo_busca}): {e}")
    
    # Pausa de 2 segundos para não sobrecarregar a API gratuita (Rate Limit)
    time.sleep(2)

print("\n🚀 Carga em lote finalizada!")