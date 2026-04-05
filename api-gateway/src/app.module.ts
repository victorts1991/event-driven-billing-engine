import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BillingController } from './modules/billing/billing.controller';
import { BillingService } from './modules/billing/billing.service';
import { StripeService } from './modules/infra/payments/stripe.service';
import { SqsService } from './modules/infra/sqs/sqs.service';
import { CorrelationIdMiddleware } from './common/middleware/correlation-id.middleware';
import { Transaction } from './modules/billing/entities/transaction.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'localhost'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get<string>('DB_USERNAME'),
        password: config.get<string>('DB_PASSWORD'),
        database: config.get<string>('DB_DATABASE'),
        entities: [Transaction],
        synchronize: true,
        ssl: {
          rejectUnauthorized: false, // Permite conectar no RDS público sem erro de certificado
        },
      }),
    }),
    TypeOrmModule.forFeature([Transaction]),
  ],
  controllers: [BillingController],
  providers: [BillingService, StripeService, SqsService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}