import dht          # <-- Faltava ele! A biblioteca do sensor de temperatura/umidade
import machine
import time
import network
import urequests
import ssd1306
import secrets      # <-- O seu cofre de senhas novo

# --- CREDENCIAIS ---
SUPABASE_URL_COMPLETA = f"{secrets.SUPABASE_URL}/rest/v1/leituras_brutas_bronze"

HEADERS = {
    "apikey": secrets.SUPABASE_KEY,
    "Authorization": f"Bearer {secrets.SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

# --- SETUP DE HARDWARE ---
sensor_ar = dht.DHT22(machine.Pin(4))
sensor_solo = machine.ADC(machine.Pin(3))
sensor_solo.atten(machine.ADC.ATTN_11DB)

led_azul = machine.Pin(8, machine.Pin.OUT)
led_azul.value(1) 

i2c = machine.I2C(0, scl=machine.Pin(6), sda=machine.Pin(5))
disp = ssd1306.SSD1306_I2C(128, 64, i2c)

def ler_luz_bh1750(i2c_bus):
    """Lê a luminosidade em Lux do sensor BH1750 via I2C"""
    try:
        i2c_bus.writeto(0x23, b'\x10')
        time.sleep_ms(180) # Tempo para o sensor fotografar a luz
        dados = i2c_bus.readfrom(0x23, 2)
        lux = (dados[0] << 8 | dados[1]) / 1.2
        return round(lux, 1)
    except Exception as e:
        print("Erro ao ler BH1750:", e)
        return -1.0

def atualizar_ecra(temp, umid, solo, luz, status=""):
    try:
        disp.fill(0) 
        disp.text(f"T:{temp}C", 27, 24, 1)
        disp.text(f"U:{umid}%", 27, 32, 1)
        disp.text(f"S:{solo}", 27, 40, 1)
        disp.text(f"L:{luz}", 27, 48, 1)
        disp.text(f"BD:{status}", 27, 56, 1)
        disp.show()
    except Exception as e:
        print("Erro no ecrã:", e)

def piscar_led():
    led_azul.value(0)
    time.sleep(0.2)
    led_azul.value(1)

def conectar_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print(f"A conectar a {secrets.WIFI_SSID}...")
        atualizar_ecra("-", "-", "-", "-", "Wi-Fi..")
        wlan.connect(secrets.WIFI_SSID, secrets.WIFI_PASS)
        # Espera até 10 segundos para não ficar preso infinitamente
        tentativas = 0
        while not wlan.isconnected() and tentativas < 20:
            time.sleep(1)
            tentativas += 1
            print(".", end="")
        
    if wlan.isconnected():
        print("\nWi-Fi Conectado!")
        return True
    return False

# --- FLUXO PRINCIPAL (Executado uma vez a cada acordar) ---
try:
    if conectar_wifi():
        # 1. Leitura
        sensor_ar.measure()
        temp_atual = round(sensor_ar.temperature(), 1)
        umid_atual = round(sensor_ar.humidity(), 1)
        solo_atual = sensor_solo.read()
        luz_atual = ler_luz_bh1750(i2c)
        
        atualizar_ecra(temp_atual, umid_atual, solo_atual, luz_atual, "A enviar")
        
        # 2. Prepara o pacote
        payload = {
            "arquivo_origem": "esp32_c3_supermini",
            "dados_json": {
                "temperature_c": temp_atual,
                "humidity_pct": umid_atual,
                "soil_moisture_raw": solo_atual,
                "light_intensity_raw": luz_atual
            }
        }
        
        # 3. Dispara para a nuvem
        res = urequests.post(SUPABASE_URL_COMPLETA, headers=HEADERS, json=payload)
        
        if res.status_code == 201:
            piscar_led()
            atualizar_ecra(temp_atual, umid_atual, solo_atual, luz_atual, "OK!")
            print("Sucesso!")
        else:
            atualizar_ecra(temp_atual, umid_atual, solo_atual, luz_atual, "Erro DB")
            
        res.close()
    else:
        atualizar_ecra("E", "E", "E", "E", "Sem Net")

except Exception as e:
    print("Erro geral:", e)
    atualizar_ecra("E", "E", "E", "E", "Erro")

# 4. HIBERNAÇÃO (Deep Sleep)
# O ecrã vai continuar a mostrar a última imagem graças à energia passiva
TEMPO_SONO_MS = 900000 # 15 minutos

print(f"A entrar em Deep Sleep por {TEMPO_SONO_MS / 1000} segundos...")
machine.deepsleep(TEMPO_SONO_MS)