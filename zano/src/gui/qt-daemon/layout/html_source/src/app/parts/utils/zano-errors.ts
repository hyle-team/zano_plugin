import { ValidationErrors } from '@angular/forms';

export interface ZanoValidationErrors extends ValidationErrors {
  errorText: string;
}

export const wrongAssetId: ZanoValidationErrors = {
  errorText: 'ASSETS.FORM.ERRORS.WRONG_ASSET_ID',
};

export const wrongPassword: ZanoValidationErrors = {
  errorText: 'Wrong password',
};

export const insuficcientFunds: ZanoValidationErrors = {
  errorText: 'ASSETS.FORM.ERRORS.INSUFICCIENT_FUNDS',
};

export const notFileZanoWallet: ZanoValidationErrors = {
  errorText: 'ERRORS.NOT_FILE_ZANO_WALLET',
};
