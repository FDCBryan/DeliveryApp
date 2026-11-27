# DeliveryApp — Architecture Plan (v1)

Status: **draft for review** · 2026-11-27

## 1. What v1 does

One iOS app with two roles:

- **Customer** browses stores, picks items from one store, places an order and watches its status live.
- **Courier** sees open orders from every store, accepts one, marks it picked up, then delivered.

Many stores are supported, but each order comes from exactly one store (marketplace model).

**Not in v1:** store-owner role (stores and menus are seed data), in-app payment (cash on delivery), live courier map tracking, push notifications, ratings, multi-store carts. Each one is listed in §9 as a later milestone.

## 2. Key decisions

| Decision | Choice | Why |
|---|---|---|
| App shape | One app, role chosen at sign-up | One codebase, one auth system, the whole order flow testable in one place. The code is split by feature so it can become two app targets later. |
| UI | SwiftUI, iOS 17+, `@Observable` view models | Already the project setup; Observation avoids `ObservableObject` boilerplate. |
| Concurrency | Swift 6 style: main actor by default, `async/await`, `AsyncStream` for live updates | Matches the Xcode 27 settings already applied. |
| Backend | Firebase Auth + Cloud Firestore (Swift Package Manager) | Live order updates on both sides, transactions for safe order acceptance, no server to run. |
| Data access | Repository protocols with two implementations: Firestore and in-memory | Previews and unit tests run without the network; the backend can be swapped later. |
| Money | `Int` in minor units (e.g. centavos/cents) | No floating-point rounding errors. |

## 3. Folder layout

```text
DeliveryApp/
├─ App/                 DeliveryAppApp.swift, AppEnvironment (dependency container), RootView (role routing)
├─ Core/
│  ├─ Models/           User, Store, MenuItem, Order, OrderItem, OrderStatus, Address, Money
│  ├─ Repositories/     AuthRepository, StoreRepository, OrderRepository (protocols)
│  ├─ Firebase/         Firestore* implementations + Codable mapping
│  └─ Mock/             InMemory* implementations + sample stores/menus
├─ Features/
│  ├─ Auth/             SignIn, SignUp (with role picker)
│  ├─ Customer/
│  │  ├─ Stores/        StoreList, StoreDetail (menu)
│  │  ├─ Cart/          Cart (single store), Checkout
│  │  └─ Orders/        MyOrders, OrderTracking
│  └─ Courier/
│     ├─ Available/     AvailableOrders, OrderPreview
│     └─ Active/        ActiveDelivery, DeliveryHistory
└─ Shared/UI/           Reusable views (price label, status badge, empty/error states)
DeliveryAppTests/       Model, state-machine and view-model tests against the in-memory repositories
```

## 4. Data models

```swift
enum UserRole: String, Codable { case customer, courier }

struct AppUser: Identifiable, Codable {
    let id: String            // Firebase Auth uid
    var role: UserRole
    var name: String
    var phone: String
}

struct Store: Identifiable, Codable {
    let id: String
    var name: String
    var address: Address
    var imageURL: URL?        // cover photo (optional)
    var logoURL: URL?         // required for every store created through the app/API
    var isOpen: Bool
    var deliveryFee: Int      // minor units
    var cuisine: String
    var deliveryMinutes: Int
    var tagline: String
    var isFeatured: Bool      // "Popular near you" row
}

struct MenuItem: Identifiable, Codable {
    let id: String
    let storeID: String
    var name: String
    var price: Int
    var imageURL: URL?
    var isAvailable: Bool
}

struct OrderItem: Codable {   // snapshot copied into the order: later menu edits don't change past orders
    let menuItemID: String
    let name: String
    let unitPrice: Int
    var quantity: Int
}

struct Order: Identifiable, Codable {
    let id: String
    let customerID: String
    let storeID: String
    let storeName: String         // denormalized for list screens
    var courierID: String?
    var items: [OrderItem]
    var subtotal: Int
    var deliveryFee: Int
    var total: Int
    var deliveryAddress: Address
    var status: OrderStatus
    var createdAt: Date
    var updatedAt: Date
}

struct Address: Codable { var line: String; var note: String?; var latitude: Double?; var longitude: Double? }
```

## 5. Order lifecycle

```text
placed ──(courier accepts)──▶ accepted ──(picked up at store)──▶ pickedUp ──▶ delivered
   │
   └──(customer cancels, only while still placed)──▶ cancelled
```

- Allowed transitions live in one place, `OrderStatus.canTransition(to:by:)`, and the Firestore security rules enforce the same table.
- **Accepting an order is a Firestore transaction:** read the order, check `status == placed && courierID == nil`, then write `courierID` and `accepted`. If two couriers tap Accept together, only one wins; the other sees "Order already taken".
- A courier can have only one active delivery at a time in v1.
- When the store-owner role arrives, `preparing` and `readyForPickup` slot in between `placed` and `pickedUp`.

## 6. Firestore layout

```text
users/{uid}                      AppUser
stores/{storeID}                 Store
stores/{storeID}/menu/{itemID}   MenuItem
orders/{orderID}                 Order
```

Queries and the screens that use them:

| Screen | Query |
|---|---|
| Customer — store list | `stores` where `isOpen == true` |
| Customer — my orders | `orders` where `customerID == uid` order by `createdAt desc` |
| Customer — tracking | live listener on `orders/{id}` |
| Courier — available | `orders` where `status == "placed"` order by `createdAt` (live) |
| Courier — active | `orders` where `courierID == uid` and `status in [accepted, pickedUp]` |

Composite indexes are needed for the queries that combine a filter with a sort; they go in `firestore.indexes.json`.

**Security rules (outline):**
- `users/{uid}`: a user reads and writes only their own document, and `role` can't change after creation.
- `stores` and `menu`: anyone signed in can read; nobody can write from the app (seeded from the console or a script).
  When store creation opens (store-owner role), a store can only be created with a `logoURL` that points to an image already uploaded to Cloud Storage under `stores/{storeID}/logo`.
- `orders`:
  - Create: customers only, with `customerID == auth.uid` and `status == placed`.
  - Read: the order's customer, its assigned courier, and any courier while it's still `placed`.
  - Update: only the transitions in §5, by the right role, and `items` and totals can't change after creation.

The client also computes the order total; a Cloud Function (later) can re-check it server-side.

### Store logos and images

Every store must have a logo; a cover photo is optional.

- **In the app:** `StoreDraft.validate()` (Core/Models/StoreDraft.swift) rejects a new store without a logo, or with an image that isn't JPEG/PNG (checked from the file's bytes) or is over 2 MB. The cover photo gets the same checks when present.
- **Upload flow (M4+):** upload the logo to Cloud Storage `stores/{storeID}/logo` first, then create the store document with its download URL.
- **Backend checks:** the API and the Storage/Firestore rules must enforce the same three things (logo present, image type, 2 MB size), so the rule holds even for clients that skip the app's validation.
- **Stores without a logo image:** the sample stores, and any store whose logo fails to load, show a monogram badge (the store's initials on its own color) so stores stay distinguishable.

## 7. Screens

**Shared:** Sign in · Sign up (name, phone, role) · Profile / sign out

**Customer** (tabs: Stores · Orders · Profile)
1. Store list: open stores, with name, image and delivery fee
2. Store detail: menu; add to cart. Adding an item from another store asks whether to clear the cart.
3. Cart / Checkout: quantities, subtotal + fee, delivery address, cash on delivery, Place order
4. My orders: active orders first, then history
5. Order tracking: live status timeline, courier name/phone once accepted, cancel while `placed`

**Courier** (tabs: Available · Active · History · Profile)
1. Available orders: live list with store, drop-off area, total, item count
2. Order preview → Accept (the transaction from §5)
3. Active delivery: store address → *Picked up* → customer address and phone → *Delivered*
4. History: completed deliveries

## 8. Testing

- **Unit tests:**
  - `OrderStatus` transition table
  - cart rules (single store, totals in minor units)
  - view models against the in-memory repositories
- **Concurrency test:** two simulated couriers accept the same order; exactly one succeeds.
- **Firebase Emulator Suite:**
  - security-rules tests
  - running the app locally without touching production data
- **Manual end-to-end:** two simulators, one signed in as a customer and one as a courier, take one order from placed to delivered.

## 9. Milestones

| # | Milestone | Done when |
|---|---|---|
| M1 | Foundation: models, repository protocols, in-memory data, role routing, test target | Both role UIs navigate on mock data; tests pass |
| M2 | Customer flow on mock data | Browse → cart → place → see order status |
| M3 | Courier flow on mock data | Available → accept → picked up → delivered, visible to the customer in the same run |
| M4 | Firebase: Auth, Firestore repositories, seed script, rules, indexes, emulator | Same flows across two simulators with live updates |
| M5 | Polish: errors/empty states, pull to refresh, app icon, bundle ID | Ready for TestFlight |
| Later | Store onboarding: store-owner sign-up, create-store form using `StoreDraft` (logo required), logo/cover upload to Cloud Storage | A new store appears in the list with its own logo |
| Later | Store-owner role · push notifications (APNs + Cloud Functions) · live courier location on a map · online payment · ratings · courier approval | — |

Building M1–M3 on mock data first means the screens and the state machine are settled before any Firebase setup.

## 10. Open questions for you

1. **Currency and region:** which currency, and does the delivery fee vary by store or by distance? (The plan assumes a flat per-store fee.)
2. **Courier sign-up:** can anyone pick "Courier" at sign-up, or must couriers be approved first? (The plan assumes open sign-up for v1.)
3. **Bundle ID:** the current one is the template default `com.DeliveryApp.DeliveryApp`. What should it be? Firebase registers the app by bundle ID, so this must be settled before M4.
4. **Store data:** do you have real stores and menus to seed, or should I invent sample data?
5. **Delivery address:** typed text only for v1, or pick a point on a map (adds MapKit and location permission)?
