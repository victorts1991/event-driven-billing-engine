import { Controller, Post, Body, Req, InternalServerErrorException } from '@nestjs/common';
import { BillingService } from './billing.service';
import { v4 as uuidv4 } from 'uuid';

@Controller('billing')
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

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
}