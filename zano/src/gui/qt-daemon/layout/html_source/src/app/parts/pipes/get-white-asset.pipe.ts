import { Pipe, PipeTransform } from '@angular/core';
import { Asset, WhiteAssetInfo } from '@api/models/assets.model';
import { AssetsFacade } from '@store/assets/assets.facade';
import { Observable } from 'rxjs';

@Pipe({
  name: 'getWhiteAsset',
  standalone: true,
})
export class GetWhiteAssetPipe implements PipeTransform {
  constructor(private assetsFacade: AssetsFacade) {}
  transform(asset_id: Asset['asset_info']['asset_id']): Observable<WhiteAssetInfo | undefined> {
    return this.assetsFacade.getAssetByIdFromWhitelist(asset_id);
  }
}
