#!/usr/bin/env python3

import sys
import requests
import json
import codecs
import re
import datetime

sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

API_TOKEN = "TOKEN_AQUI"

def formatar_cpf(cpf):
    """Formata um CPF de 'XXXXXXXXXXX' para 'XXX.XXX.XXX-XX'."""
    if len(cpf) == 11 and cpf.isdigit():
        return "{}.{}.{}-{}".format(cpf[:3], cpf[3:6], cpf[6:9], cpf[9:])
    return cpf

def get_cpf_from_agi():
    """Lê o CPF passado pelo Asterisk via AGI."""
    cpf = None
    for line in sys.stdin:
        line = line.strip()
        if line.startswith("agi_arg_1:"):
            cpf = line.split(":")[1].strip()
            break
    return cpf

def consultar_cliente(cpf):
    """Consulta a API de clientes e retorna o nome e o contrato."""
    url = "https://suportetsmx.sgp.net.br/api/ura/clientes/"

    payload = {
        "app": "ura",
        "token": API_TOKEN,
        "cpfcnpj": cpf
    }

    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }

    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        response_data = response.json()

        if response_data.get("paginacao", {}).get("total", 0) > 0:
            cliente = response_data["clientes"][0]
            nome_cliente = cliente.get("nome", "Desconhecido")  # Se não houver nome, define "Desconhecido"
            contrato_id = cliente.get("contratos", [{}])[0].get("id", "0")

            print('SET VARIABLE CPF_RESULT "OK"')
            print('SET VARIABLE CLIENTE_NOME "{}"'.format(nome_cliente))  # Agora sempre define um nome
            print('SET VARIABLE CLIENTE_CONTRATO "{}"'.format(contrato_id))

            return contrato_id, nome_cliente
        else:
            print('SET VARIABLE CPF_RESULT "NOK"')
            print('SET VARIABLE CLIENTE_NOME "Desconhecido"')  # Nome definido mesmo se a API falhar
            print('SET VARIABLE CLIENTE_CONTRATO "0"')
            return "0", "Desconhecido"

    except requests.exceptions.RequestException as e:
        print('SET VARIABLE CPF_RESULT "NOK"')
        print('SET VARIABLE CLIENTE_NOME "Erro na consulta"')
        print('SET VARIABLE CLIENTE_CONTRATO "0"')
        print("Erro de requisição:", e)
        return "0", "Erro na consulta"

def consultar_financeiro(cpf):
    """Consulta se o cliente tem faturas em aberto."""
    url = "https://suportetsmx.sgp.net.br/api/ura/titulos/"

    payload = {
        "app": "ura",
        "token": API_TOKEN,
        "cpfcnpj": cpf
    }

    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }

    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        response_data = response.json()

        if response_data.get("paginacao", {}).get("total", 0) > 0:
            valor_aberto = response_data["titulos"][0].get("valorCorrigido", 0)
            print('SET VARIABLE CONTRATO_VALOR_ABERTO "{}"'.format(valor_aberto))
        else:
            print('SET VARIABLE CONTRATO_VALOR_ABERTO "0"')

    except requests.exceptions.RequestException as e:
        print('SET VARIABLE CONTRATO_VALOR_ABERTO "0"')
        print("Erro de requisição:", e)


def liberar_por_confianca(contrato_id):
    """Solicita a liberação do contrato por confiança."""
    url = "https://suportetsmx.sgp.net.br/api/ura/liberacaopromessa/"

    payload = {
        "app": "ura",
        "token": API_TOKEN,
        "contrato": contrato_id,
        "data_promessa": datetime.datetime.today().strftime('%Y-%m-%d')
    }

    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }

    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        response_data = response.json()

        # Captura a liberação e protocolo corretamente
        liberado = bool(response_data.get("liberado", False))
        protocolo = str(response_data.get("protocolo", "N/A")).strip()

        if liberado:
            print('SET VARIABLE LIBERACAO_CONF "OK"')
            print('SET VARIABLE LIBERACAO_PROTOCOLO "{}"'.format(protocolo))
        else:
            print('SET VARIABLE LIBERACAO_CONF "Erro"')
            print('SET VARIABLE LIBERACAO_PROTOCOLO "N/A"')
            print("Erro na resposta da API: {response_data}")

    except requests.exceptions.RequestException as e:
        print('SET VARIABLE LIBERACAO_CONF "Erro"')
        print('SET VARIABLE LIBERACAO_PROTOCOLO "N/A"')
        print("Erro de requisição: {}".format(e))

    finally:
        sys.stdout.flush()  # Garante que o Asterisk receba a resposta corretamente

if __name__ == "__main__":
    cpf = get_cpf_from_agi()
    if cpf:
        cpf_formatado = formatar_cpf(cpf)
        print("Testando consulta com CPF formatado: {}".format(cpf_formatado))

        contrato_id, nome_cliente = consultar_cliente(cpf_formatado)
        consultar_financeiro(cpf_formatado)

        # Se o script foi chamado para liberação, executa a liberação
        if len(sys.argv) > 2 and sys.argv[2] == "LIBERAR":
            liberar_por_confianca(contrato_id)
        else:
            print('SET VARIABLE LIBERACAO_CONF "PENDENTE"')
            print('SET VARIABLE LIBERACAO_PROTOCOLO "N/A"')

    else:
        print('SET VARIABLE CPF_RESULT "NOK"')
        print('SET VARIABLE CLIENTE_NOME "Desconhecido"')
        print('SET VARIABLE CONTRATO_VALOR_ABERTO "0"')
        print('SET VARIABLE CLIENTE_CONTRATO "0"')
        print('SET VARIABLE LIBERACAO_CONF "Erro"')
        print("Erro: CPF não informado")

    sys.stdout.flush()
