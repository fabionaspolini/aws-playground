exports.handler = async function (input, context) {
    console.info("Exemplo simples de uma função lambda para converter os caracteres para maiúsculo.")
    return input.toUpperCase()
}