import network
import time

# Preencha com os dados do seu Wi-Fi
NOME_REDE = ""
SENHA_REDE = ""

def conectar_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    
    # --- A MÁGICA PARA RESOLVER O ERRO DE STATE ---
    # Força a placa a cancelar qualquer conexão travada do passado
    wlan.disconnect() 
    time.sleep(1) # Dá 1 segundo para o rádio Wi-Fi respirar
    # ----------------------------------------------
    
    print(f"Conectando na rede: {NOME_REDE}...")
    wlan.connect(NOME_REDE, SENHA_REDE)
    
    # Vamos dar até 15 segundos dessa vez
    tentativas = 0
    while not wlan.isconnected() and tentativas < 15:
        print(".", end="")
        time.sleep(1)
        tentativas += 1
            
    if wlan.isconnected():
        print("\nSucesso! Conectado ao Wi-Fi. 🎉")
        config = wlan.ifconfig()
        print(f"IP da placa: {config[0]}")
    else:
        print("\nFalha ao conectar. Verifique a senha ou o sinal do roteador.")

# Roda a função
conectar_wifi()