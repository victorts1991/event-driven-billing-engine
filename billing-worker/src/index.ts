import 'dotenv/config';
import { SQSClient, ReceiveMessageCommand, DeleteMessageCommand, ChangeMessageVisibilityCommand } from "@aws-sdk/client-sqs";
import { pgClient, updateTransactionStatus } from './database/pg-client'; 
import { isDuplicate, redisClient } from './redis/client';

const sqs = new SQSClient({ region: process.env.AWS_REGION });
const QUEUE_URL = process.env.AWS_SQS_QUEUE_URL!;

async function processMessages() {
  try {
    const response = await sqs.send(new ReceiveMessageCommand({
      QueueUrl: QUEUE_URL,
      MaxNumberOfMessages: 1,
      WaitTimeSeconds: 20 // Long Polling
    }));

    if (!response.Messages) return;

    for (const message of response.Messages) {
      const body = JSON.parse(message.Body!);
      const { transactionId, correlationId, amount } = body;

      console.log(`[${correlationId}] Processando cobrança: ${transactionId}`);

      // 1. Verificação de Idempotência
      const duplicated = await isDuplicate(correlationId);
      if (duplicated) {
        console.warn(`[${correlationId}] Mensagem duplicada ignorada.`);
        await deleteMessage(message.ReceiptHandle!);
        continue;
      }

      try {
        
        // 2. Persistência no Banco
        await updateTransactionStatus(transactionId, 'SUCCEEDED');

        // 3. Sucesso: Deleta da fila
        await deleteMessage(message.ReceiptHandle!);
        console.log(`[${correlationId}] Transação finalizada com sucesso.`);
        
      } catch (error) {
            console.error(`[${correlationId}] Erro ao processar transação ${transactionId}:`, error);

            // Se o erro for de negócio (ex: saldo insuficiente), marcamos como FAILED no banco e tiramos da fila
            // Verificamos se o erro é um objeto e possui a propriedade 'type'
            if (error && typeof error === 'object' && 'type' in error && error.type === 'BUSINESS_ERROR') {
                await updateTransactionStatus(transactionId, 'FAILED');
                await deleteMessage(message.ReceiptHandle!);
            } else {
                // Se for erro de infra (ex: Timeout do Banco), NÃO deletamos. 
                // A mensagem voltará para a fila após o Visibility Timeout definido no AWS SQS.
                console.log(`[${correlationId}] Erro de infra. A mensagem voltará para a fila para retry.`);
            }
      }
    }
  } catch (err) {
    console.error("Erro no Worker loop:", err);
  }
}

async function deleteMessage(receiptHandle: string) {
  await sqs.send(new DeleteMessageCommand({
    QueueUrl: QUEUE_URL,
    ReceiptHandle: receiptHandle
  }));
}

async function start() {
  console.log("🚀 Tentando conectar ao Postgres...");
  await pgClient.connect();
  console.log("✅ Postgres conectado!");

  console.log("🚀 Tentando conectar ao Redis...");
  await redisClient.connect();
  console.log("✅ Redis conectado!");
  
  console.log("📥 Iniciando consumo da fila SQS...");
  while (true) {
    await processMessages();
  }
}

start().catch(console.error);