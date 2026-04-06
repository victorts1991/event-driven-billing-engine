import { Test, TestingModule } from '@nestjs/testing';
import { BillingService } from './billing.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Transaction } from './entities/transaction.entity';
import { StripeService } from '../infra/payments/stripe.service';
import { SqsService } from '../infra/sqs/sqs.service';

describe('BillingService (Unit Test - 100% Mocked)', () => {
  let service: BillingService;
  let stripeMock: any;
  let sqsMock: any;
  let repoMock: any;

  beforeEach(async () => {
    // Definindo os comportamentos dos Mocks
    stripeMock = {
      createPaymentIntent: jest.fn().mockResolvedValue({ id: 'pi_mock_123' }),
    };

    sqsMock = {
      sendMessage: jest.fn().mockResolvedValue({ MessageId: 'msg_123' }),
    };

    repoMock = {
      create: jest.fn().mockImplementation((dto) => ({ id: 'uuid-123', ...dto })),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BillingService,
        { provide: getRepositoryToken(Transaction), useValue: repoMock },
        { provide: StripeService, useValue: stripeMock },
        { provide: SqsService, useValue: sqsMock },
      ],
    }).compile();

    service = module.get<BillingService>(BillingService);
  });

  it('deve orquestrar o checkout com sucesso sem chamar serviços externos', async () => {
    const amount = 150.5;
    const correlationId = 'test-cid-999';

    const result = await service.processIntent({ amount }, correlationId);

    // 1. Verifica se chamou o Stripe com o valor convertido para centavos (Stripe padrão)
    expect(stripeMock.createPaymentIntent).toHaveBeenCalledWith(amount, correlationId);

    // 2. Verifica se persistiu no banco com status inicial correto
    expect(repoMock.create).toHaveBeenCalledWith(expect.objectContaining({
      amount: amount,
      status: 'pending',
      correlationId: correlationId
    }));
    expect(repoMock.save).toHaveBeenCalled();

    // 3. Verifica se disparou a mensagem para o SQS para o Worker processar
    expect(sqsMock.sendMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        event: 'PAYMENT_INITIALIZED',
        transactionId: 'uuid-123'
      }),
      correlationId
    );

    // 4. Resposta da API
    expect(result).toEqual({
      status: 'transaction_initiated',
      transactionId: 'uuid-123',
      correlationId: correlationId
    });
  });

  it('deve lançar erro se o Stripe falhar (garantindo isolamento)', async () => {
    stripeMock.createPaymentIntent.mockRejectedValue(new Error('Stripe Down'));
    
    await expect(service.processIntent({ amount: 10 }, 'cid'))
      .rejects.toThrow('Stripe Down');
    
    // Garante que se o Stripe falhou, o SQS nem foi chamado
    expect(sqsMock.sendMessage).not.toHaveBeenCalled();
  });
});