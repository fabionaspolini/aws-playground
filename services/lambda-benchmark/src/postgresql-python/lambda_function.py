import logging
import os
import psycopg2
import psycopg2
from psycopg2.extras import RealDictCursor

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(input, context):
    logger.info('Iniciando postgresql-python (Teste comparação .NET vs NodeJS vs Python)')
    print_pessoas()
    logger.info('Concluído')

def print_pessoas():
    # connectionString = "host=lambda-test.cblgcoxiefix.us-east-1.rds.amazonaws.com dbname=lambda_test port=8455 user=postgres password=teste.123456"

    connectionString = os.getenv('ConnectionString')
    conn = psycopg2.connect(connectionString, cursor_factory=RealDictCursor)

    # crie um cursor para executar comandos SQL
    cur = conn.cursor()

    # execute uma consulta SQL
    cur.execute("select * from pessoa")

    # recupere os resultados da consulta
    rows = cur.fetchall()

    # imprima os resultados
    for row in rows:
        print(row["id"] + ", " + row["nome"] + ", " + row["data_nascimento"].strftime("%d/%m/%Y"))

    # feche o cursor e a conexão com o banco de dados
    cur.close()
    conn.close()
