// -------------------------------------------------------------------------------------------------
//  Copyright (C) 2015-2024 Nautech Systems Pty Ltd. All rights reserved.
//  https://nautechsystems.io
//
//  Licensed under the GNU Lesser General Public License Version 3.0 (the "License");
//  You may not use this file except in compliance with the License.
//  You may obtain a copy of the License at https://www.gnu.org/licenses/lgpl-3.0.en.html
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
// -------------------------------------------------------------------------------------------------

use anyhow::Result;
use nautilus_model::enums::{LiquiditySide, OrderSide};
use nautilus_model::events::account::state::AccountState;
use nautilus_model::events::order::filled::OrderFilled;
use nautilus_model::instruments::Instrument;
use nautilus_model::position::Position;
use nautilus_model::types::balance::AccountBalance;
use nautilus_model::types::currency::Currency;
use nautilus_model::types::money::Money;
use nautilus_model::types::price::Price;
use nautilus_model::types::quantity::Quantity;
use std::collections::HashMap;

pub trait Account {
    fn balance_total(&self, currency: Option<Currency>) -> Option<Money>;
    fn balances_total(&self) -> HashMap<Currency, Money>;
    fn balance_free(&self, currency: Option<Currency>) -> Option<Money>;
    fn balances_free(&self) -> HashMap<Currency, Money>;

    fn balance_locked(&self, currency: Option<Currency>) -> Option<Money>;
    fn balances_locked(&self) -> HashMap<Currency, Money>;
    fn last_event(&self) -> Option<AccountState>;
    fn events(&self) -> Vec<AccountState>;
    fn event_count(&self) -> usize;
    fn currencies(&self) -> Vec<Currency>;
    fn starting_balances(&self) -> HashMap<Currency, Money>;
    fn balances(&self) -> HashMap<Currency, AccountBalance>;
    fn apply(&mut self, event: AccountState);
    fn calculate_balance_locked<T: Instrument>(
        &mut self,
        instrument: T,
        side: OrderSide,
        quantity: Quantity,
        price: Price,
        use_quote_for_inverse: Option<bool>,
    ) -> Result<Money>;

    fn calculate_pnls<T: Instrument>(
        &self,
        instrument: T,
        fill: OrderFilled,
        position: Option<Position>,
    ) -> Result<Vec<Money>>;

    fn calculate_commission<T: Instrument>(
        &self,
        instrument: T,
        last_qty: Quantity,
        last_px: Price,
        liquidity_side: LiquiditySide,
        use_quote_for_inverse: Option<bool>,
    ) -> Result<Money>;
}

pub mod base;
pub mod cash;
pub mod margin;

#[cfg(test)]
pub mod stubs;
