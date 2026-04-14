import 'dotenv/config';
import { SQSClient, ReceiveMessageCommand, DeleteMessageCommand } from "@aws-sdk/client-sqs";
import { pgClient, updateTransactionStatus } from './database/pg-client'; 
import { isDuplicate, redisClient } from './redis/client';

const sqs = new SQSClient({ region: process.env.AWS_REGION });
const QUEUE_URL = process.env.AWS_SQS_QUEUE_URL!;

// Flag para controle do ciclo de vida
let isRunning = true;
let isProcessing = false;

async function processMessages() {
  if (!isRunning) return;
  
  try {
    isProcessing = true;
    const response = await sqs.send(new ReceiveMessageCommand({
      QueueUrl: QUEUE_URL,
      MaxNumberOfMessages: 1,
      WaitTimeSeconds: 20 
    }));

    if (!response.Messages || response.Messages.length === 0) {
      isProcessing = false;
      return;
    }

    for (const message of response.Messages) {
      const body = JSON.parse(message.Body!);
      const { transactionId, correlationId } = body;

      console.log(`[${correlationId}] Processando cobrança: ${transactionId}`);

      const duplicated = await isDuplicate(correlationId);
      if (duplicated) {
        console.warn(`[${correlationId}] Mensagem duplicada ignorada.`);
        await deleteMessage(message.ReceiptHandle!);
        continue;
      }

      try {
        await updateTransactionStatus(transactionId, 'SUCCEEDED');
        await deleteMessage(message.ReceiptHandle!);
        console.log(`[${correlationId}] Transação finalizada com sucesso.`);
      } catch (error: any) {
        console.error(`[${correlationId}] Erro ao processar:`, error);
        
        if (error?.type === 'BUSINESS_ERROR') {
          await updateTransactionStatus(transactionId, 'FAILED');
          await deleteMessage(message.ReceiptHandle!);
        }
        // Erros de infra não deletam a mensagem (retry automático do SQS)
      }
    }
  } catch (err) {
    console.error("Erro no Worker loop:", err);
  } finally {
    isProcessing = false;
  }
}

async function deleteMessage(receiptHandle: string) {
  await sqs.send(new DeleteMessageCommand({
    QueueUrl: QUEUE_URL,
    ReceiptHandle: receiptHandle
  }));
}

// --- FUNÇÃO DE SHUTDOWN ---
const shutdown = async (signal: string) => {
  console.log(`\n[${signal}] Iniciando encerramento gracioso...`);
  isRunning = false; // Para o loop de receber novas mensagens

  // Aguarda o processamento atual terminar (max 15s)
  let checks = 0;
  while (isProcessing && checks < 15) {
    console.log("Aguardando finalização da mensagem em curso...");
    await new Promise(resolve => setTimeout(resolve, 1000));
    checks++;
  }

  try {
    console.log("Fechando conexões...");
    await Promise.all([
      pgClient.end(),
      redisClient.quit()
    ]);
    console.log("✅ Conexões encerradas. Saindo.");
    process.exit(0);
  } catch (err) {
    console.error("Erro ao fechar conexões:", err);
    process.exit(1);
  }
};

// Escuta os sinais do Kubernetes
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

async function start() {
  await pgClient.connect();
  await redisClient.connect();
  console.log("📥 Worker pronto e ouvindo SQS...");

  while (isRunning) {
    await processMessages();
  }
}

start().catch(async (err) => {
  console.error("Erro fatal no start:", err);
  process.exit(1);
});