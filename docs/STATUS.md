# DeliveryApp — Project Status

Last updated: 2026-11-27 · Branch: `claude/vigilant-fermi-f7d385`

DeliveryApp is one iOS app with two roles: **customers** order food from many stores, and **couriers** deliver it. Each order comes from one store. The full plan, with data models, order rules, the Firebase layout and milestones, is in [PLAN.md](PLAN.md).

**Where it stands:** milestones M1–M3 are built and run entirely on **in-memory sample data**. There's no backend yet, so nothing is shared between devices and everything resets when the app restarts. Connecting the real backend (Firebase) is M4.

| Milestone | Status |
|---|---|
| M1 — Foundation (models, data layer, sign-in, roles, tests) | ✅ Done |
| M2 — Customer flow (browse → cart → checkout → track → cancel) | ✅ Done, checked on the simulator |
| M3 — Courier flow (available → accept → picked up → delivered) | ✅ Built and unit-tested · ⚠️ not yet walked through on the simulator |
| M4 — Firebase backend | ⏳ Not started |
| M5 — Polish and TestFlight | ⏳ Not started |
| Later — store owners, notifications, maps, payments, … | ⏳ Not started |

---

## 1. What works today

### Customer
- **Store list:**
  - search by store name, cuisine or description
  - cuisine filter chips
  - a swipeable deals banner and a "Popular near you" row
  - compact store cards showing delivery time, fee and a free-delivery badge
- **Store logos:** every store has its own logo. Until a real logo image exists, a round badge shows the store's initials on its own color (e.g. BB, CC).
- **Store page:**
  - a stretchy banner behind a see-through navigation bar
  - the store info card overlapping the banner
  - a category bar pinned at the top that jumps to each section
  - menu items with description, price, thumbnail and a sold-out state
- **Cart:**
  - red **+** buttons on menu items that show the quantity once added
  - a floating "View cart" bar
  - items from one store only: adding from another store asks to start a new cart
  - quantity steppers, capped at 20 per item
- **Checkout:**
  - delivery address and an optional note for the courier
  - cash on delivery
  - subtotal, delivery fee and total
  - the last-used address is filled in next time
- **Order tracking:** a live status timeline and the courier's name with a call button once assigned. The order can be cancelled while it's still "Placed".

### Courier
- **Available tab:** every unassigned order from all stores, updated live, with a badge showing how many are waiting.
- **Order screen:**
  - one action button for the courier's next step: **Accept order → Picked up from store → Delivered**
  - a cash-collection confirmation before "Delivered"
  - Apple Maps directions to the pickup and drop-off addresses
- **Privacy:** the customer's phone number is hidden until the courier accepts the order.
- **Safe acceptance:** only one courier can win an order. The others see "Another courier already took this order". A cancelled order shows "no longer available".
- **One delivery at a time:** a courier can hold only one active delivery.
- **Active tab:** the current delivery, then a "Delivery complete" screen with the cash collected.
- **History tab:** finished deliveries with totals (count, cash collected, delivery fees).

### Shared
- Sign in, sign up with a role choice, sign out.
- Red/yellow brand palette (inspired by Jollibee's colors, in original shades), with light and dark variants.
- **Store creation rules,** ready for the store-owner feature: a new store must have a JPEG or PNG logo of 2 MB or less (checked from the file's contents). It also needs a name, cuisine, address, a fee that isn't negative, and a delivery time between 5 and 180 minutes. See `StoreDraft`.

### Tests
- **69 unit tests (Swift Testing), all passing** (the count treats each multi-input test as one). They cover:
  - the order status rules
  - atomic order acceptance, including two couriers racing
  - the in-memory backend and its live updates
  - cart rules and checkout
  - customer cancel
  - each courier step
  - one full journey from customer to courier and back to the customer, in one app run
  - auth, menu grouping, store logo initials, store creation validation, and sample data consistency

---

## 2. How to try it

1. Open `DeliveryApp.xcodeproj` in Xcode 27 (minimum iOS 17) and run the **DeliveryApp** scheme.
2. On the sign-in screen, use **Sign in as demo customer** or **Sign in as demo courier**. These buttons appear only in Debug builds.
3. To play both sides in one run:
   1. As the customer, place an order.
   2. Go to **Profile → Switch to demo courier**.
   3. Accept the order, mark it picked up, then delivered.
   4. Switch back to the customer to see it delivered.
4. **Shortcut:** launch with the argument `-demoRole customer` or `-demoRole courier` to start already signed in. This only works in Debug builds.
5. Run the tests with ⌘U, or:
   ```bash
   xcodebuild test -project DeliveryApp.xcodeproj -scheme DeliveryApp -destination 'platform=iOS Simulator,name=iPhone 17'
   ```

---

## 3. Not done yet (in the plan)

### M3 follow-up
- [ ] Walk through the courier flow on the simulator: accept, pick up, deliver, and the customer seeing each step. The unit tests already cover this logic end to end.

### M4 — Firebase backend
- [ ] Create the Firebase project and register the app. This needs the final bundle ID (see open questions).
- [ ] Add Firebase Auth and Firestore with Swift Package Manager.
- [ ] Write Firestore versions of the three data protocols (`AuthRepository`, `StoreRepository`, `OrderRepository`), replacing the in-memory ones.
- [ ] Make order acceptance a **Firestore transaction**, so only one courier can win across devices.
- [ ] Security rules matching the order status rules, and no writes to stores or menus from the app.
- [ ] Composite indexes (`firestore.indexes.json`).
- [ ] A seed script for stores and menus.
- [ ] Firebase Emulator Suite for local development and security-rules tests.
- [ ] **Re-check prices on the server at checkout.** Right now the cart keeps the price from when an item was added.
- [ ] **Logo upload:** logos go to Cloud Storage under `stores/{storeID}/logo`, and the backend enforces the same checks as `StoreDraft` (present, JPEG or PNG, 2 MB or less).
- [ ] Check on two simulators that one order updates live on both: customer on one, courier on the other.

### M5 — Polish and release
- [ ] A real app icon (the asset catalog slot is empty).
- [ ] The final bundle ID (currently the template default `com.DeliveryApp.DeliveryApp`).
- [ ] Better error, offline and loading states everywhere, plus pull-to-refresh where it's missing.
- [ ] Accessibility pass: VoiceOver labels, Dynamic Type at large sizes, contrast of the red/yellow palette.
- [ ] TestFlight build.

### Later (after v1)
- [ ] **Store-owner role and store onboarding:** owner sign-up, a create-store form using `StoreDraft` (logo required), menu editing, and accepting or preparing orders. This adds the statuses `preparing` and `readyForPickup`.
- [ ] Push notifications, e.g. "courier accepted", "order delivered", "new order nearby" (APNs + Cloud Functions).
- [ ] Live courier location on a map for the customer.
- [ ] Online payment (currently cash on delivery only).
- [ ] Ratings and reviews.
- [ ] Courier approval before they can take orders (currently anyone can sign up as a courier).
- [ ] Real promotions from the backend. The deals banner is currently built from store data.
- [ ] Real "Popular near you" based on order counts or distance. It's currently a fixed flag on each store.
- [ ] Item photos and store cover photos. Items and banners currently use colored placeholders.
- [ ] Picking the delivery address on a map (MapKit + location permission).

### Open questions (decisions needed — PLAN.md §10)
1. **Currency and region**, and whether the delivery fee is flat per store or by distance. Prices currently show **USD as a placeholder**.
2. Can anyone sign up as a courier, or must couriers be approved first?
3. **Bundle ID.** This blocks M4, because Firebase registers the app by bundle ID.
4. Real store and menu data, or keep the sample data for now?
5. Delivery address as typed text only, or picked on a map?

---

## 4. Known limitations of the current build
- **Everything is sample data in memory.** Orders, carts and accounts are lost when the app restarts, and there's nothing shared between devices.
- **Demo accounts are fake.** Their sign-in buttons appear only in Debug builds.
- **The cart lives only while the app is open,** and it's cleared on sign-out.
- **A courier can't un-accept an order** or report a problem; there's no support flow.
- **Placeholder pictures** stand in for every store banner and menu item.

---

## 5. Code map

```text
DeliveryApp/
├─ App/              App entry, AppSession (signed-in user, cart, data access), RootView (role routing)
├─ Core/
│  ├─ Models/        User, Store, MenuItem/MenuSection, Order, OrderStatus, Cart, StoreDraft, Money
│  ├─ Repositories/  Auth / Store / Order protocols (the only way the app reaches data)
│  └─ Mock/          In-memory implementations + sample stores, menus, accounts, orders
├─ Features/
│  ├─ Auth/          Sign in / sign up
│  ├─ Customer/      Store list, store page, cart & checkout, my orders, CustomerRouter
│  └─ Courier/       Available, active delivery, history, CourierRouter
└─ Shared/UI/        Order screen (both roles), store logo, artwork, brand colors, profile
DeliveryAppTests/    Unit tests (Swift Testing)
docs/                PLAN.md (architecture), STATUS.md (this file)
```
