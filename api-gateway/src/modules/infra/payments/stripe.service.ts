import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Stripe from 'stripe'; 

@Injectable()
export class StripeService {
  private readonly stripe: Stripe.Stripe;

  constructor(private readonly config: ConfigService) {
    const apiKey = this.config.get<string>('STRIPE_SECRET_KEY');

    if (!apiKey) {
      throw new Error('STRIPE_SECRET_KEY não encontrada no .env');
    }

    this.stripe = (Stripe as any)(apiKey, {
      apiVersion: '2026-03-25.dahlia',
      typescript: true,
    });
  }

  constructEvent(payload: Buffer, signature: string): any {
    const webhookSecret = this.config.get<string>('STRIPE_WEBHOOK_SECRET');
    return this.stripe.webhooks.constructEvent(payload, signature, webhookSecret!);
  }

  async createPaymentIntent(amount: number, correlationId: string): Promise<any> {
    try {
      
      return await this.stripe.paymentIntents.create({
        amount: Math.round(amount * 100),
        currency: 'brl',
        metadata: { correlationId },
      });
    } catch (error) {

      console.error('[Stripe SDK Error]:', error);

      throw new InternalServerErrorException('Erro ao criar intenção de pagamento no Stripe');
    }
  }
}