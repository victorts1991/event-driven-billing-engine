import { createClient } from 'redis';
import 'dotenv/config';
import { ConnectionOptions } from 'tls';

const endpoint = process.env.REDIS_ENDPOINT || 'localhost';
const port = process.env.REDIS_PORT || '6379';

let redisUrl: string;

// 1. Se já for uma URL completa (como a do seu Terraform), usa ela
if (endpoint.startsWith('redis://') || endpoint.startsWith('rediss://')) {
  redisUrl = endpoint;
} else {
  // 2. Se for só o host, monta a string garantindo que não duplica a porta
  const host = endpoint.includes(':') ? endpoint : `${endpoint}:${port}`;
  redisUrl = `redis://${host}`;
}

console.log('[Redis] Tentando conectar na URL final:', redisUrl);
  
const tlsOptions: ConnectionOptions | undefined = redisUrl.startsWith('rediss') 
  ? { rejectUnauthorized: false } 
  : undefined;

const redisClient = createClient({
  url: redisUrl,
  socket: {
    connectTimeout: 10000,
    // Se a URL for rediss://, configuramos o TLS
    tls: tlsOptions as any
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