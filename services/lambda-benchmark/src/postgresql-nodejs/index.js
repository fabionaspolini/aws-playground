const { Client } = require('pg');
const moment = require('moment');

exports.handler = async (event, context) => {
    console.info("Iniciando postgresql-nodejs")

    const config = {
        connectionString: process.env.ConnectionString,
        ssl: {
          rejectUnauthorized: false
        }
      };

    // Cria uma nova instância do cliente PostgreSQL
    const client = new Client(config);

    try {
        // Conecta ao banco de dados
        await client.connect();

        // Executa uma consulta na tabela desejada
        const res = await client.query('select * from pessoa');

        // Retorna os resultados da consulta
        res.rows.forEach(row => {
            const dataNascimento = moment(row.data_nascimento).format('DD/MM/YYYY');
            console.info(`${row.id}, ${row.nome}, ${dataNascimento}`);
        });

    } catch (err) {
        console.error(err);
        throw err;
    } finally {
        // Encerra a conexão com o banco de dados
        await client.end();
    }
    console.info("Concluído")
};