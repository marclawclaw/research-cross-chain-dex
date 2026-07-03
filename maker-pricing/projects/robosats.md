---
title: RoboSats — Maker Pricing Configuration
tags: [p2p, lightning, robosats, pricing, maker-daemon]
created: 2026-07-03
status: complete
---

# RoboSats — Maker Pricing Configuration

RoboSats is a Lightning-native P2P Bitcoin exchange that minimises custody through Lightning hold invoices. It is federated: multiple independent coordinators share a common open-source codebase. Makers post orders; takers fill them.

Sources: [[sources/2026-07-03-robosats-order-backend.py]], [[sources/2026-07-03-robosats-logics.py]], [[sources/2026-07-03-robosats-views.py]], [[sources/2026-07-03-robosats-maker-model.ts]], [[sources/2026-07-03-robosats-makerform.tsx]]

---

## 1. All Maker-Configurable Pricing Parameters

### 1.1 `premium` — Percentage Premium Over Market Price

**The primary pricing knob.** The maker specifies a signed percentage premium relative to the coordinator's cached market rate.

- **Range:** −99.99% to +999% for fiat orders; −99.99% to +99% for swap (LN↔onchain) orders.
- **Semantics:** Positive = maker receives more fiat per BTC (more expensive for buyer). Negative = maker discounts their BTC price (cheaper for buyer).
- **Default:** 0 (at market).
- **Precision:** Stored to 2 decimal places (`DecimalField(max_digits=5, decimal_places=2)`).
- **Effect:** `trade_price = market_price × (1 + premium / 100)`. Satoshis are computed as `sats = (fiat_amount / trade_price) × 100_000_000`.
- **Marked-to-market:** The premium is fixed at order creation; the actual satoshi amount floats continuously with the market rate until the taker bond is locked, at which point `last_satoshis` is finalised.

Source: `api/models/order.py` lines 90–96, `api/logics.py` lines 220–258, `MakerForm.tsx` lines 213–234.
Accessed: 2026-07-03. URL: https://github.com/RoboSats/robosats/blob/main/api/models/order.py

### 1.2 `is_explicit` / `satoshis` — Fixed-Satoshi (Explicit) Pricing Mode

Makers can bypass the premium/market-price model entirely by setting `is_explicit = true` and specifying a fixed `satoshis` amount.

- When `is_explicit` is true, `premium` is ignored; the order trades exactly `satoshis` sats regardless of market movement.
- `satoshis` must be within `MIN_TRADE` (20,000 sats) and `MAX_TRADE` (5,000,000 sats).
- The front-end UI does not prominently expose this toggle (it is an advanced/API option); the serializer accepts it via `MakeOrderSerializer`.
- This is equivalent to a "fixed price" order — the maker bears zero market risk while the order is public.

Source: `api/models/order.py` lines 87–105, `api/logics.py` line 228.
Accessed: 2026-07-03. URL: https://github.com/RoboSats/robosats/blob/main/api/models/order.py

### 1.3 `currency` — Fiat Currency Selection

- Identified by an integer ID (1 = USD, 2 = EUR, etc.) from `currencies.json`.
- Over 80 currencies supported, plus currency 1000 (swap mode: Lightning ↔ on-chain BTC).
- Currency selection determines which price feed entry is used. The coordinator maintains a `Currency` model caching `exchange_rate` (fiat per BTC) for each currency.
- The maker's fiat amount and premium are always interpreted relative to the selected currency's cached rate.
- Switching currency resets the amount range to sensible defaults in the UI (`min_amount = max_amount × 0.25`, `max_amount = max_amount × 0.75`).

Source: `api/models/currency.py`, `MakerForm.tsx` lines 150–179, `frontend/static/assets/currencies.json`.
Accessed: 2026-07-03. URL: https://github.com/RoboSats/robosats/blob/main/frontend/static/assets/currencies.json

### 1.4 `amount`, `min_amount` / `max_amount`, `has_range` — Trade Size

Two mutually exclusive modes:

**Fixed amount** (`has_range = false`):
- Single `amount` field in fiat units (or BTC for swap mode).
- Converted to satoshis at creation using current market rate + premium.
- Must be within the coordinator's per-currency fiat limits (derived from `MIN_ORDER_SIZE` / `MAX_ORDER_SIZE` in sats, converted at current price × premium).

**Range order** (`has_range = true`):
- `min_amount` and `max_amount` set the fiat range a taker may choose within.
- Taker specifies their exact amount at take-time; satoshis are computed then.
- `max_amount` is additionally bounded by the coordinator's `size_limit` (a per-coordinator satoshi ceiling converted to fiat at current price).
- Constraint: `min_sats > max_sats / 15` (min cannot be less than 1/15 of max) and `min_sats < max_sats / 1.5` (min cannot exceed 2/3 of max).
- The UI also applies safe thresholds of ×1.03 on min and ×0.98 on max to ensure valid requests.

Global sats limits (coordinator-configurable via env): 20,000 sats minimum, 5,000,000 sats maximum (TheBigLake live data: `min_order_size: 20000`, `max_order_size: 5000000`).

Source: `api/models/order.py` lines 73–83, `api/logics.py` lines 102–141, `api/views.py` lines 140–151, `MakerForm.tsx` lines 119–137.
Accessed: 2026-07-03. URL: https://github.com/RoboSats/robosats/blob/main/api/logics.py

### 1.5 `payment_method` — Payment Method String

- Free-text field, max 70 characters.
- No pricing effect — purely informational for the taker.
- The UI offers a curated autocomplete list (Revolut, SEPA, PayPal, Cash, etc.) with logos; custom entries accepted.
- Special case: selecting "F2F" (face-to-face cash) opens a map to pin a (slightly randomised) geolocation (`latitude`, `longitude` fields).
- Affects taker selection (buyers/sellers filter orders by payment method) but does not modify the price formula.

Source: `api/models/order.py` lines 84–86, `MakerForm.tsx` lines 185–212, serializer help text line 581.
Accessed: 2026-07-03.

### 1.6 `public_duration` — Order Public Expiry

- How long the order remains in the public order book before expiring (if untaken).
- **Unit:** seconds.
- **Default:** 23h 59m 59s (86,399 seconds — i.e. `60 × 60 × DEFAULT_PUBLIC_ORDER_DURATION - 1` with `DEFAULT_PUBLIC_ORDER_DURATION = 24`).
- **Min:** 10 minutes (600 seconds, i.e. `60 × 60 × 0.166`).
- **Max:** 24 hours (86,400 seconds).
- **UI control:** A time-picker in HH:mm format (advanced options), range 00:10 to 23:59.
- Maker-configurable: the maker can post short-lived (e.g. 30 min) or near-maximum (23:59) orders.
- If the order expires untaken, the maker bond hold invoice is cancelled and the maker may re-post.

Source: `api/models/order.py` lines 107–120, `MakerForm.tsx` lines 281–293, 1038–1045, `robosats/settings.py` lines 288–292.
Accessed: 2026-07-03. URL: https://github.com/RoboSats/robosats/blob/main/robosats/settings.py

### 1.7 `escrow_duration` — Escrow/Invoice Lock Window

- How long the seller has to post the trade escrow hold invoice, and the buyer has to post their payout invoice, after the taker bond is locked.
- **Unit:** seconds.
- **Default:** 2h 59m 59s (10,799 seconds — `60 × INVOICE_AND_ESCROW_DURATION - 1` with `INVOICE_AND_ESCROW_DURATION = 180` minutes).
- **Min:** 30 minutes (1,800 seconds).
- **Max:** 10 hours (36,000 seconds).
- **UI control:** Time-picker HH:mm, range 01:00 to 10:00.
- **Maker-configurable:** Yes — the maker sets the window. A longer window reduces the risk of honest counterparties timing out due to connectivity; a shorter window reduces the maker's market exposure during the escrow phase.
- This same timer governs both the WFI (waiting for invoice) and WFE (waiting for escrow) statuses.

Source: `api/models/order.py` lines 122–131, `MakerForm.tsx` lines 310–327, 1046–1079.
Accessed: 2026-07-03.

### 1.8 `bond_size` — Fidelity Bond Percentage

- Both maker and taker lock the same bond percentage of the trade value as a hold invoice.
- **Range:** 2% to 15% of `last_satoshis`.
- **Default:** 3%.
- **Step:** 0.25% (slider in UI).
- **UI marks:** 2%, 5%, 10%, 15%.
- **Maker-configurable:** Yes — the maker sets the bond size for both sides. Takers must agree to the maker's bond size.
- Bond sats = `round(last_satoshis × bond_size / 100)`.
- **Effect on counterparty:** Higher bond = stronger Schelling point against cheating/griefing; lower bond = easier to take, wider taker pool.
- **Returned on completion:** Both bonds are released (hold invoice cancelled) if the trade completes successfully. Lost (settled) on unilateral cancellation or dispute loss.

Source: `api/models/order.py` lines 133–144, `api/logics.py` lines 1265–1267, `MakerForm.tsx` lines 492–499, 1122–1146.
Accessed: 2026-07-03.

### 1.9 `description` — Order Description (Advanced)

- Optional free-text field, max 240 characters.
- No pricing effect; used by maker to communicate trade terms (e.g. "SEPA only, EUR region, fast settlement").
- Advanced option, hidden behind the toggle.

### 1.10 `password` — Order Password (Advanced)

- Optional SHA-256-hashed password. If set, only robots that know the password can take the order.
- Stored as SHA-256 hash of the maker-supplied string (`sha256(password)` in the frontend before sending).
- No pricing effect; used for private/negotiated orders.

---

## 2. Price Oracle

### 2.1 Architecture

RoboSats does **not** use a single oracle. Each coordinator independently fetches and caches BTC/fiat exchange rates from multiple public APIs, then takes a **nanmedian** (numpy's NaN-aware median) across all available sources.

The function `get_exchange_rates(currencies)` in `api/utils.py` polls each configured `MARKET_PRICE_APIS` URL and aggregates:

| Source | API URL pattern | Notes |
|--------|----------------|-------|
| Blockchain.info | `blockchain.info/ticker` | ARS excluded (known mis-pricing) |
| Yadio.io | `api.yadio.io/exrates/BTC` | Good emerging-market coverage |
| BitPay | `bitpay.com/...` | Skipped when Tor proxy is active |
| CriptoYa | `criptoya.com/...` | Latin American currencies only; skipped on Tor |

**TheBigLake live data (2026-07-03):** `"market_price_apis": "https://blockchain.info/ticker, https://api.yadio.io/exrates/BTC"`

Results are **cached in-process for 30 seconds** using `ring.dict`. A Celery task (`cache_market`) periodically calls this and stores the median rate into the `Currency.exchange_rate` database field.

Source: `api/utils.py` lines 161–259, `api/tasks.py` function `cache_market`, live API response from TheBigLake coordinator.
Accessed: 2026-07-03. URL: https://github.com/RoboSats/robosats/blob/main/api/utils.py

### 2.2 Price Formula

```
sats = (fiat_amount / (exchange_rate × (1 + premium / 100))) × 100_000_000
```

Or equivalently:

```
trade_price_fiat_per_btc = exchange_rate × (1 + premium / 100)
sats = (fiat_amount / trade_price_fiat_per_btc) × 100_000_000
```

Source: `api/logics.py` lines 220–223.

### 2.3 Satoshi Finalisation at Taker Bond

The satoshi count (`last_satoshis`) is **re-computed at every status check** while the order is public (marked-to-market), then **locked in permanently** when the taker's bond invoice is confirmed locked (`contract_is_locked` in `logics.py` around line 1333). After that point, `last_satoshis` does not change even if the market moves.

This creates a **window of market risk** for both parties between when the taker initiates and when both bonds are settled.

Source: `api/logics.py` lines 1265, 1333, 1401.
Accessed: 2026-07-03.

### 2.4 Unavailable Price Feed

If `get_exchange_rates()` returns `None` (all APIs unreachable), the `cache_market` task prints an error and returns without updating the database. The coordinator continues using the **last cached `exchange_rate`** in the database until a fresh rate is fetched. The UI shows "The Bitcoin price is not synchronized" and disables order creation (`currentPrice === undefined`).

Source: `api/tasks.py` function `cache_market`, `api/utils.py` lines 253–254, `MakerForm.tsx` lines 448–451.
Accessed: 2026-07-03.

### 2.5 Maker Control Over Price Feed

**None.** The price feed is entirely determined by the coordinator's `.env` configuration (`MARKET_PRICE_APIS`). Makers have no ability to specify or override the price source for their orders. All orders on a given coordinator use the same median rate.

---

## 3. Coordinator Model and Fees

### 3.1 Federated Architecture

RoboSats v0.8.x operates as a federation of independent coordinators. As of 2026-07-03, there are **6 coordinators** in `federation.json`: temple, lake, moon, bazaar, freedomsats, alice. Each runs the same open-source codebase but configures its own:

- Fee levels (`FEE`, `MAKER_FEE_SPLIT` env vars)
- Order size limits (`MIN_ORDER_SIZE`, `MAX_ORDER_SIZE`)
- Price API sources (`MARKET_PRICE_APIS`)
- Swap parameters

Makers choose which coordinator to use at order creation time (`shortAlias` field). The coordinator routes all communications and holds the bonds.

### 3.2 Coordinator Fees

Fees are set entirely by the coordinator operator via environment variables. **Makers cannot set or negotiate fees.** The total fee (`FEE`) is split between maker and taker via `MAKER_FEE_SPLIT`:

- `maker_fee = FEE × MAKER_FEE_SPLIT`
- `taker_fee = FEE × (1 − MAKER_FEE_SPLIT)`

**TheBigLake live fee data (2026-07-03):**
- `maker_fee: 0.00025` (0.025%)
- `taker_fee: 0.00175` (0.175%)
- Implied total `FEE ≈ 0.002` (0.2%) with `MAKER_FEE_SPLIT ≈ 0.125`

The fee is deducted from `last_satoshis`:
- **Seller** (escrow poster): escrow = `last_satoshis + fee_sats` (they deposit more)
- **Buyer** (invoice submitter): invoice = `last_satoshis − fee_sats` (they receive less)

Source: `api/logics.py` lines 17–18, 700–710, 778–788; live API response `https://unsafe.thebiglake.org/api/info/`.
Accessed: 2026-07-03.

### 3.3 Coordinator Fee — Not Maker-Adjustable

The coordinator fee is **not configurable by makers**. It is a coordinator-level parameter applied uniformly to all orders on that coordinator. Makers can choose a cheaper coordinator if desired, but cannot individually negotiate a lower rate.

### 3.4 `default_bond_size` in Coordinator Info

The coordinator's `info` endpoint exposes `bond_size: 3` (TheBigLake, 2026-07-03) as the **default**, but makers can override it to any value in [2%, 15%].

---

## 4. Adoption Metrics

As of 2026-07-03:

| Metric | Value | Source |
|--------|-------|--------|
| GitHub stars | 1,005 | https://api.github.com/repos/RoboSats/robosats |
| GitHub forks | 226 | https://api.github.com/repos/RoboSats/robosats |
| Repo last updated | 2026-07-01 | https://api.github.com/repos/RoboSats/robosats |
| TheBigLake lifetime volume | 142.9 BTC | https://unsafe.thebiglake.org/api/info/ |
| TheBigLake 24h volume | 0.237 BTC | https://unsafe.thebiglake.org/api/info/ |
| TheBigLake active robots today | 1,673 | https://unsafe.thebiglake.org/api/info/ |
| TheBigLake public buy orders | 16 | https://unsafe.thebiglake.org/api/info/ |
| TheBigLake public sell orders | 20 | https://unsafe.thebiglake.org/api/info/ |
| TheBigLake 24h avg premium | +2.89% | https://unsafe.thebiglake.org/api/info/ |
| Federation coordinators | 6 | https://github.com/RoboSats/robosats/blob/main/frontend/static/federation.json |
| License | AGPL-3.0 | https://github.com/RoboSats/robosats |

Note: TheBigLake is one of 6 coordinators. Total network volume is distributed across all coordinators; per-coordinator data for others requires direct query to their Tor onion endpoints.

All metrics accessed: 2026-07-03.

---

## 5. Lightning-Specific Pricing Considerations

### 5.1 Routing Fees and Effective Trade Price

The buyer submits a Lightning invoice to receive sats. The buyer can optionally specify a `routing_budget_ppm` (parts per million) when submitting their invoice (max 100,001 ppm = ~10%). The coordinator deducts `routing_budget_sats = last_satoshis × routing_budget_ppm / 1_000_000` from the payout amount to cover routing.

Default `routing_budget_ppm` is 0; the client-side default is 1,000 ppm (0.1%) per the `follow_send_payment` task comment.

The maker is not exposed to routing fees directly — the maker receives or pays fiat; it is the coordinator paying out sats to the buyer who handles the routing budget. However, for a **maker daemon acting as buyer**, the effective received sats = `last_satoshis − fee_sats − routing_budget_sats`.

Source: `api/logics.py` lines 901–905, `api/tasks.py` function `follow_send_payment`.
Accessed: 2026-07-03.

### 5.2 Hold Invoice Mechanism and Maker Pricing Risk

RoboSats uses Lightning hold invoices (HTLC-based) for both bonds and the trade escrow:

1. **Maker bond:** Locked when the maker submits the order; released when a taker bonds (order goes to contract) or returned if the order expires untaken.
2. **Taker bond:** Locked when a taker picks up the order.
3. **Trade escrow:** The seller locks the full trade amount (+ fee) as a hold invoice for the duration of the fiat exchange.

**Maker pricing risk during public phase:** The `premium` is fixed, but `last_satoshis` re-computes with every market tick. If the market moves significantly while the order is public, the actual satoshi amount changes. This is by design (marked-to-market) — the maker is protected from having a stale fixed price order taken at an unfavourable rate. The finalisation at taker-bond-lock is the maker's exposure point.

**Maker bond CLTV locktime:** The maker bond's Lightning HTLC is timelocked to cover the full `public_duration + taker_take_window + escrow_duration + fiat_exchange_time` with an additional safety multiplier (`MAX_MINING_NETWORK_SPEEDUP_EXPECTED`). The maker's sats are frozen for this entire period.

Source: `api/logics.py` lines 1228–1248, 1250–1300.
Accessed: 2026-07-03.

---

## 6. Limitations and Risks

### 6.1 Free-Option Risk
During the public phase, any taker can observe the order and decide to take it only when market conditions are favourable (i.e., the market moved against the maker). The taker bond mitigates but does not eliminate this: a taker who bonds and then refuses to complete pays the bond as a penalty, but the maker still spent the public_duration holding a bond.

### 6.2 Hold Invoice Griefing
The maker bond HTLC is locked for the entire order lifecycle (potentially 24h + 3h + fiat exchange time). A malicious coordinator could delay releasing the hold invoice, locking the maker's liquidity. The AGPL-3.0 open-source code mitigates coordinator trust (operators can be audited), but it does not eliminate the risk of a rogue coordinator.

### 6.3 Price Oracle Single Point of Failure Per Coordinator
Each coordinator maintains its own price cache. If a coordinator's APIs are unreachable, it serves stale rates. There is no cross-coordinator price consensus or fallback to another coordinator's feed. A maker whose coordinator serves stale rates may transact at an unintentionally mispriced rate.

### 6.4 Coordinator Trust
Coordinators hold bonds and the trade escrow as HTLC preimages. A coordinator can, in theory, settle the escrow and pocket funds, though this would destroy their reputation. The federation model distributes trust but each trade is fully at-risk with one coordinator.

### 6.5 No Maker Price Update
Once an order is public, the maker **cannot update** the premium or amount. They must cancel (losing the maker bond time, and potentially paying a penalty if a taker is already bonded) and re-post. There is a `pause` action to temporarily delist an order, but no price-edit action.

Source: `api/logics.py` around line 1076–1131 (cancel logic), `UpdateOrderSerializer` actions list.
Accessed: 2026-07-03.

---

## Summary for Daemon Developers

A RoboSats-style maker daemon needs to manage:

| Parameter | Type | Range | Default | Notes |
|-----------|------|-------|---------|-------|
| `premium` | `Decimal(5,2)` | −99.99% to +999% | 0 | Primary pricing knob; marked-to-market |
| `is_explicit` | `bool` | true/false | false | Fixed sats mode bypasses oracle |
| `satoshis` | `int` | 20k–5M | null | Only if `is_explicit=true` |
| `currency` | `int` | 1–1000+ | 1 (USD) | Determines oracle feed used |
| `amount` | `Decimal` | fiat or BTC | null | Fixed size (if `has_range=false`) |
| `min_amount` / `max_amount` | `Decimal` | per-currency limits | null | Range order |
| `has_range` | `bool` | true/false | false | Enables range orders |
| `payment_method` | `str` | max 70 chars | "not specified" | No pricing effect |
| `public_duration` | `int` (secs) | 600–86400 | 86399 | How long order lives |
| `escrow_duration` | `int` (secs) | 1800–36000 | 10799 | Escrow lock window |
| `bond_size` | `Decimal(4,2)` | 2%–15% | 3% | Both sides; step 0.25% |
| `description` | `str` | max 240 chars | null | Optional free text |
| `password` | `str` (hashed) | any | null | SHA-256 hash; private orders |

The coordinator fee is not under maker control. Choose coordinator by fee level and reputation.

---

## Links

- Repository: https://github.com/RoboSats/robosats
- Learn site: https://learn.robosats.org
- Federation.json: https://github.com/RoboSats/robosats/blob/main/frontend/static/federation.json
- Order model: https://github.com/RoboSats/robosats/blob/main/api/models/order.py
- Logics: https://github.com/RoboSats/robosats/blob/main/api/logics.py
- MakerForm UI: https://github.com/RoboSats/robosats/blob/main/frontend/src/components/MakerForm/MakerForm.tsx
