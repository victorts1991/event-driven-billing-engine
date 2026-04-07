import { Client } from 'pg';
import 'dotenv/config';

export const pgClient = new Client({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE,
  ssl: {
    rejectUnauthorized: false // Permite o certificado auto-assinado do RDS
  }
});

export async function updateTransactionStatus(id: string, status: 'SUCCEEDED' | 'FAILED') {
  await pgClient.query(
    'UPDATE transactions SET status = $1, "updatedAt" = NOW() WHERE id = $2',
    [status, id]
  );
}