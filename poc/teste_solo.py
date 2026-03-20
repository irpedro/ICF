import machine
import time

# Configura o pino 3 (em vez do 32) para ler sinais analógicos
pino_solo = machine.ADC(machine.Pin(3))

# Essa linha diz pro ESP32 ler a voltagem toda (de 0 a 3.3V)
pino_solo.atten(machine.ADC.ATTN_11DB)

print("Lendo a umidade bruta do solo... (Aperte Ctrl+C para parar)")

while True:
    try:
        # Lê o valor bruto
        leitura_bruta = pino_solo.read()
        print(f"Valor bruto do solo: {leitura_bruta}")
        time.sleep(1)
        
    except Exception as e:
        print("Erro ao ler o pino 3.")