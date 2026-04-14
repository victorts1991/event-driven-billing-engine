import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common/pipes/validation.pipe';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    rawBody: true, // ESSENCIAL para validar assinatura do Stripe
  });
  app.useGlobalPipes(new ValidationPipe());

  app.enableShutdownHooks();
  
  await app.listen(3000);
}

bootstrap();
