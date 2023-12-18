import { Component, inject, NgZone } from '@angular/core';
import { NonNullableFormBuilder, Validators } from '@angular/forms';
import { BackendService } from '@api/services/backend.service';
import { VariablesService } from '@parts/services/variables.service';
import { ModalService } from '@parts/services/modal.service';
import { Router } from '@angular/router';
import { Wallet } from '@api/models/wallet.model';
import { TranslateService } from '@ngx-translate/core';
import { regExpPassword, ZanoValidators } from '@parts/utils/zano-validators';
import { WalletsService } from '@parts/services/wallets.service';

@Component({
  selector: 'app-create-wallet',
  template: `
    <div class="page-container">
      <div class="toolbar mb-2">
        <div class="left">
          <button
            appBackButton
            class="btn-icon circle big mr-2"
            type="button"
          >
            <i class="icon dropdown-arrow-left"></i>
          </button>
          <h1>{{ 'BREADCRUMBS.ADD_WALLET' | translate }}</h1>
        </div>
        <div class="right"></div>
      </div>

      <div class="page-content">
        <div class="breadcrumbs mb-2">
          <div class="breadcrumb">
            <a [routerLink]="['/add-wallet']">{{ 'BREADCRUMBS.ADD_WALLET' | translate }}</a>
          </div>
          <div class="breadcrumb">
            <span>{{ 'BREADCRUMBS.CREATE_WALLET' | translate }}</span>
          </div>
        </div>

        <div class="scrolled-content">
          <form
            [formGroup]="createForm"
            class="form"
          >
            <div class="form__field">
              <label for="wallet-name">{{ 'CREATE_WALLET.NAME' | translate }}</label>
              <input
                (contextmenu)="variablesService.onContextMenu($event)"
                [placeholder]="'PLACEHOLDERS.WALLET_NAME_PLACEHOLDER' | translate"
                [readonly]="createForm.controls.path.valid"
                class="form__field--input"
                formControlName="name"
                id="wallet-name"
                maxlength="{{ variablesService.maxWalletNameLength }}"
                type="text"
              />
              <div
                *ngIf="createForm.controls.name.invalid && (createForm.controls.name.dirty || createForm.controls.name.touched)"
                class="error"
              >
                <div *ngIf="createForm.controls.name.hasError('duplicate')">
                  {{ 'CREATE_WALLET.FORM_ERRORS.NAME_DUPLICATE' | translate }}
                </div>
                <div *ngIf="createForm.controls.name.hasError('required')">
                  {{ 'CREATE_WALLET.FORM_ERRORS.NAME_REQUIRED' | translate }}
                </div>
              </div>
              <div
                *ngIf="createForm.controls.name.value.length > variablesService.maxWalletNameLength"
                class="error"
              >
                {{ 'CREATE_WALLET.FORM_ERRORS.MAX_LENGTH' | translate }}
              </div>
            </div>

            <div class="form__field">
              <label for="wallet-password">{{ 'CREATE_WALLET.PASS' | translate }}</label>
              <input
                (contextmenu)="variablesService.onContextMenuPasteSelect($event)"
                [readonly]="createForm.controls.path.valid"
                class="form__field--input"
                formControlName="password"
                id="wallet-password"
                placeholder="{{ 'PLACEHOLDERS.PLACEHOLDER_NEW' | translate }}"
                type="password"
              />
              <div
                *ngIf="createForm.controls.path.dirty && createForm.controls.password.invalid"
                class="error"
              >
                <div *ngIf="createForm.controls.password.hasError('pattern')">
                  {{ 'ERRORS.WRONG_PASSWORD' | translate }}
                </div>
              </div>
            </div>

            <div class="form__field">
              <label for="confirm-wallet-password">{{ 'CREATE_WALLET.CONFIRM' | translate }}</label>
              <input
                (contextmenu)="variablesService.onContextMenuPasteSelect($event)"
                [class.invalid]="createForm.hasError('mismatch') && createForm.controls.confirm.value.length > 0"
                [readonly]="createForm.controls.path.valid"
                class="form__field--input"
                formControlName="confirm"
                id="confirm-wallet-password"
                placeholder="{{ 'PLACEHOLDERS.PLACEHOLDER_CONFIRM' | translate }}"
                type="password"
              />
              <div
                *ngIf="createForm.controls.confirm.dirty && createForm.hasError('mismatch') && createForm.controls.confirm.value.length > 0"
                class="error"
              >
                {{ 'CREATE_WALLET.FORM_ERRORS.CONFIRM_NOT_MATCH' | translate }}
              </div>
            </div>

            <button
              *ngIf="createForm.controls.path.valid"
              class="outline big w-100 mb-2"
              disabled
              type="button"
            >
              <i class="icon check-circle mr-1"></i>
              {{ savedWalletName }}
            </button>

            <button
              *ngIf="createForm.controls.path.invalid"
              (click)="selectWalletLocation()"
              [disabled]="createForm.controls.name.invalid || createForm.controls.password.invalid || createForm.hasError('mismatch')"
              class="outline big w-100 mb-2"
              type="button"
            >
              {{ 'CREATE_WALLET.BUTTON_SELECT' | translate }}
            </button>

            <button
              (click)="createWallet()"
              [disabled]="createForm.invalid"
              class="primary big w-100"
              type="button"
            >
              {{ 'CREATE_WALLET.BUTTON_CREATE' | translate }}
            </button>
          </form>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      :host {
        width: 100%;
        height: 100%;
        overflow: hidden;
      }
    `,
  ],
})
export class CreateWalletComponent {
  variablesService = inject(VariablesService);

  walletsService = inject(WalletsService);

  fb = inject(NonNullableFormBuilder);
  createForm = this.fb.group(
    {
      name: this.fb.control('', [Validators.required, ZanoValidators.duplicate(this.variablesService.walletNamesForComparisons)]),
      password: this.fb.control('', Validators.pattern(regExpPassword)),
      confirm: this.fb.control(''),
      path: this.fb.control('', Validators.required),
    },
    {
      validators: [ZanoValidators.formMatch('password', 'confirm')],
    }
  );
  private router = inject(Router);
  private backend = inject(BackendService);
  private modalService = inject(ModalService);
  private ngZone = inject(NgZone);
  private translate = inject(TranslateService);

  get savedWalletName(): string {
    const path = this.createForm.get('path').value;
    return path.substr(path.lastIndexOf('/') + 1, path.length - 1);
  }

  createWallet(): void {
    const { path: selectedPath, password, name } = this.createForm.getRawValue();
    this.backend.generateWallet(selectedPath, password, async (generate_status, generate_data, errorCode) => {
      if (generate_status) {
        const { wallet_id } = generate_data;
        const { path, address, balance, unlocked_balance, mined_total, tracking_hey } = generate_data['wi'];
        const wallet = new Wallet(wallet_id, name, password, path, address, balance, unlocked_balance, mined_total, tracking_hey);
        wallet.alias = this.backend.getWalletAlias(address);
        wallet.total_history_item = 0;
        wallet.pages = new Array(1).fill(1);
        wallet.totalPages = 1;
        wallet.currentPage = 1;
        await this.backend.runWallet(wallet_id, async (run_status, run_data) => {
          if (run_status) {
            await this.ngZone.run(async () => {
              this.walletsService.addWallet(wallet);
              if (this.variablesService.appPass) {
                this.backend.storeSecureAppData();
              }
              this.variablesService.setCurrentWallet(wallet_id);
              await this.router.navigate(['/seed-phrase'], { queryParams: { wallet_id } });
            });
          } else {
            console.log(run_data['error_code']);
          }
        });
      } else {
        const errorTranslationKey =
          errorCode === 'ALREADY_EXISTS' ? 'CREATE_WALLET.ERROR_CANNOT_SAVE_TOP' : 'CREATE_WALLET.ERROR_CANNOT_SAVE_SYSTEM';
        this.modalService.prepareModal('error', errorTranslationKey);
      }
    });
  }

  selectWalletLocation(): void {
    const caption = this.translate.instant('CREATE_WALLET.TITLE_SAVE');
    const fileMask = '*';
    const { default_path } = this.variablesService.settings;
    this.backend.saveFileDialog(caption, fileMask, default_path, (file_status, file_data) => {
      if (file_status) {
        this.ngZone.run(() => {
          const { path } = file_data;
          this.createForm.get('path').patchValue(path);
          this.variablesService.settings.default_path = path.substr(0, path.lastIndexOf('/'));
        });
      }
    });
  }
}
