import { createClient } from 'redis';
import 'dotenv/config';

const redisUrl = `redis://${process.env.REDIS_ENDPOINT}:${process.env.REDIS_PORT || '6379'}`;
const redisClient = createClient({
  url: redisUrl,
  socket: {
    connectTimeout: 5000 
  }
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));

export async function isDuplicate(correlationId: string): Promise<boolean> {
  if (!redisClient.isOpen) await redisClient.connect();
  
  // Tenta definir uma chave que expira em 24h. 
  // 'NX' garante que só funciona se a chave NÃO existir.
  const result = await redisClient.set(`processed:${correlationId}`, 'true', {
    NX: true,
    EX: 86400 
  });

  return result === null; // Se retornar null, a chave já existia (duplicado)
}

export { redisClient };