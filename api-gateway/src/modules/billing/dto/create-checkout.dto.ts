import { IsNumber, IsString, IsNotEmpty, Min, IsUUID } from 'class-validator';

export class CreateCheckoutDto {
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1, { message: 'O valor mínimo para cobrança é R$ 1.00' })
  @IsNotEmpty()
  amount!: number;

  @IsString()
  @IsNotEmpty()
  customerId!: string;

  @IsString()
  @IsNotEmpty()
  @IsUUID('4', { message: 'O ID do produto deve ser um UUID válido' })
  productId!: string;
}