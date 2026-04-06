import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SqsService } from '../infra/sqs/sqs.service';
import { StripeService } from '../infra/payments/stripe.service';
import { Transaction } from './entities/transaction.entity';

@Injectable()
export class BillingService {
  constructor(
    @InjectRepository(Transaction)
    private readonly transactionRepo: Repository<Transaction>,
    private readonly stripeService: StripeService,
    private readonly sqsService: SqsService
  ) {}

  async processIntent(data: { amount: number }, correlationId: string) {

    console.log(`[BillingService] Iniciando checkout. CID: ${correlationId}`);
    
    const paymentIntent = await this.stripeService.createPaymentIntent(data.amount, correlationId);

    const transaction = this.transactionRepo.create({
      correlationId,
      stripePaymentIntentId: paymentIntent.id,
      amount: data.amount,
      status: 'pending',
    });
    
    const savedTransaction = await this.transactionRepo.save(transaction);

    const message = {
      transactionId: savedTransaction.id,
      paymentIntentId: paymentIntent.id,
      amount: data.amount,
      correlationId,
      event: 'PAYMENT_INITIALIZED'
    };

    await this.sqsService.sendMessage(message, correlationId);

    return { 
      status: 'transaction_initiated', 
      transactionId: savedTransaction.id,
      correlationId 
    };
  }
}