import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const correlationId = req.headers['x-correlation-id'] || uuidv4();
    
    // Injeta no request para os serviços acessarem
    req['correlationId'] = correlationId;
    
    // Devolve no response para o cliente saber o ID da transação dele
    res.setHeader('x-correlation-id', correlationId);
    next();
  }
}