import { 
  Controller, 
  Post, 
  Body, 
  Req, 
  InternalServerErrorException, 
  Headers, 
  BadRequestException,
  RawBodyRequest
} from '@nestjs/common';
import { Request } from 'express';
import { StripeService } from '../infra/payments/stripe.service';
import { SqsService } from '../infra/sqs/sqs.service';
import { BillingService } from './billing.service';
import { v4 as uuidv4 } from 'uuid';

@Controller('billing')
export class BillingController {
  constructor(
    private readonly billingService: BillingService,
    private readonly stripeService: StripeService,
    private readonly sqsService: SqsService       
  ) {}

  @Post('checkout')
  async createCheckout(@Body() body: { amount: number }, @Req() req: any) {
    try {
      // Prioriza o correlationId do middleware, senão gera um novo
      const correlationId = req['correlationId'] || uuidv4();
      
      if (!body.amount || body.amount <= 0) {
        throw new Error('Valor inválido para o checkout');
      }

      return await this.billingService.processIntent(body, correlationId);
    } catch (error) {
      console.error('[BillingController] Erro:', error);
      throw new InternalServerErrorException(error);
    }
  }

  @Post('webhook')
  async handleStripeWebhook(
    @Headers('stripe-signature') signature: string, 
    @Req() req: RawBodyRequest<Request>, 
  ) {
    if (!signature) throw new BadRequestException('Missing signature');

    try {
      // O rawBody vem do buffer bruto necessário para o HMAC
      const event = this.stripeService.constructEvent(req.rawBody!, signature);
      
      const metadata = (event.data.object as any).metadata;
      const correlationId = metadata?.correlationId || uuidv4();

      await this.sqsService.sendMessage({
        type: event.type,
        data: event.data.object,
        correlationId
      }, correlationId);

      return { received: true };
    } catch (err) {
      console.error('[Webhook Error]:', err);
      throw new BadRequestException(`Webhook Error: ${err}`);
    }
  }
}