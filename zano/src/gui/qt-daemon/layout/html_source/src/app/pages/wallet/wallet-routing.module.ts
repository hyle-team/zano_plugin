import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { WalletComponent } from './wallet/wallet.component';
import { paths, pathsChildrenWallet } from '../paths';
import { SendComponent } from './tabs/send/send.component';
import { ReceiveComponent } from './tabs/receive/receive.component';
import { HistoryComponent } from './tabs/history/history.component';
import { StakingComponent } from './tabs/staking/staking.component';
import { AssetsComponent } from './tabs/assets/assets.component';
import { WithSidebarLayoutComponent } from '../../layouts/with-sidebar-layout/with-sidebar-layout.component';

const routes: Routes = [
  {
    path: paths.wallet,
    component: WithSidebarLayoutComponent,
    children: [
      {
        path: '',
        component: WalletComponent,
        children: [
          {
            path: pathsChildrenWallet.assets,
            component: AssetsComponent,
          },
          {
            path: pathsChildrenWallet.send,
            component: SendComponent,
          },
          {
            path: pathsChildrenWallet.receive,
            component: ReceiveComponent,
          },
          {
            path: pathsChildrenWallet.history,
            component: HistoryComponent,
          },
          {
            path: pathsChildrenWallet.staking,
            component: StakingComponent,
          },
          {
            path: '',
            redirectTo: pathsChildrenWallet.assets,
            pathMatch: 'full',
          },
        ],
      },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class WalletRoutingModule {}
