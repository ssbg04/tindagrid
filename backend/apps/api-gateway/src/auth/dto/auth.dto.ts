import { IsNotEmpty, IsOptional, IsString, Length, Matches } from 'class-validator';

export class RegisterDto {
  @IsNotEmpty()
  @IsString()
  @Matches(/^(09|\+639)\d{9}$/, {
    message: 'Ang numero ng telepono ay dapat wastong Philippine mobile number (hal. 09171234567 o +639171234567)',
  })
  phone!: string;

  @IsNotEmpty()
  @IsString()
  @Length(2, 100)
  fullName!: string;

  @IsNotEmpty()
  @IsString()
  @Matches(/^\d{4,6}$/, {
    message: 'Ang Store PIN ay dapat 4 hanggang 6 na numero lamang',
  })
  pin!: string;

  @IsOptional()
  @IsString()
  securityQuestion?: string;

  @IsOptional()
  @IsString()
  securityAnswer?: string;

  @IsOptional()
  @IsString()
  backupEmail?: string;

  @IsOptional()
  @IsString()
  storeName?: string;
}

export class LoginDto {
  @IsNotEmpty()
  @IsString()
  phone!: string;

  @IsNotEmpty()
  @IsString()
  pin!: string;
}

export class RecoverPinDto {
  @IsNotEmpty()
  @IsString()
  phone!: string;

  @IsNotEmpty()
  @IsString()
  securityQuestion!: string;

  @IsNotEmpty()
  @IsString()
  securityAnswer!: string;

  @IsNotEmpty()
  @IsString()
  @Matches(/^\d{4,6}$/, {
    message: 'Ang bagong Store PIN ay dapat 4 hanggang 6 na numero lamang',
  })
  newPin!: string;
}

export class RefreshTokenDto {
  @IsNotEmpty()
  @IsString()
  refreshToken!: string;
}
