import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(input, context):
    logger.info('Exemplo simples de uma função lambda para converter os caracteres para maiúsculo.')
    return input.upper()