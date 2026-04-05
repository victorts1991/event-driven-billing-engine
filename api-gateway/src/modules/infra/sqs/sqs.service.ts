import { SQSClient, SendMessageCommand, SendMessageCommandOutput } from "@aws-sdk/client-sqs";
import { Injectable, InternalServerErrorException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

@Injectable()
export class SqsService {
  private readonly client: SQSClient;

  constructor(private readonly config: ConfigService) {
    this.client = new SQSClient({
      region: this.config.get<string>('AWS_REGION'),
      endpoint: this.config.get<string>('AWS_SQS_ENDPOINT'), // Essencial para Localstack
      credentials: {
        accessKeyId: this.config.get<string>('AWS_ACCESS_KEY_ID', 'test'),
        secretAccessKey: this.config.get<string>('AWS_SECRET_ACCESS_KEY', 'test'),
      }
    });
  }

  async sendMessage(body: any, correlationId: string): Promise<SendMessageCommandOutput> {
    try {
      const command = new SendMessageCommand({
        QueueUrl: this.config.get<string>('AWS_SQS_QUEUE_URL'),
        MessageBody: JSON.stringify(body),
        MessageAttributes: {
          CorrelationId: { DataType: "String", StringValue: correlationId }
        }
      });

      return await this.client.send(command);
    } catch (error) {
      console.error('[AWS SQS Error]:', error);
      throw new InternalServerErrorException('Erro ao enviar mensagem para a fila SQS');
    }
  }
}