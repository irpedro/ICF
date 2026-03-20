import dht
import machine
import time

# A MÁGICA MUDA AQUI: Agora avisamos que é o DHT22
sensor = dht.DHT22(machine.Pin(4))

print("Lendo o DHT22 em tempo real... (Aperte Ctrl+C para parar)")

while True:
    try:
        # O DHT22 precisa de 2 segundos entre as leituras para não travar
        time.sleep(2) 
        sensor.measure()
        t = round(sensor.temperature(), 1)
        u = round(sensor.humidity(), 1)
        
        print(f"Temp: {t} C | Umidade: {u} %")
    except Exception as e:
        print("Falha na leitura. Verificando fios...")