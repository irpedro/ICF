from flask import Flask, request
import pg8000.dbapi
import json

app = Flask(__name__)

# Ajuste com a senha do seu PostgreSQL local
DB_CONFIG = {
    "database": "monitor_plantas", # pg8000 usa 'database' em vez de 'dbname'
    "user": "postgres",
    "password": "", # Altere para a senha do seu PostgreSQL local
    "host": "localhost",
    "port": 5432 # pg8000 prefere a porta como número inteiro
}

@app.route('/ingestao', methods=['POST'])
def receber_dados():
    dados_json = request.get_json()
    print(f"\n[+] Novo dado recebido do ESP32: {dados_json}")
    
    try:
        # Conecta no Postgres usando o driver 100% Python
        conexao = pg8000.dbapi.connect(**DB_CONFIG)
        cursor = conexao.cursor()
        
        # O pg8000 exige que os parâmetros sejam passados assim
        cursor.execute('''
            INSERT INTO leituras_brutas_bronze (arquivo_origem, dados_json)
            VALUES (%s, %s)
        ''', ('esp32_sensor_rede', json.dumps(dados_json)))
        
        conexao.commit()
        cursor.close()
        conexao.close()
        
        print("[+] Salvo no PostgreSQL com sucesso!")
        return {"status": "sucesso"}, 200
        
    except Exception as erro:
        print(f"[-] Erro ao salvar no banco: {erro}")
        return {"status": "erro"}, 500

if __name__ == '__main__':
    print("Iniciando API da Camada Bronze na porta 5000...")
    app.run(host='0.0.0.0', port=5000)