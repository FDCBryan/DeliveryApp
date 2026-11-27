import Foundation

/// Sample stores, menus, demo accounts and orders for M1–M3. Nothing here is real data.
enum MockData {
    static let demoPassword = "demo-pass-1"

    static let customer = AppUser(id: "user-customer-1", role: .customer, name: "Ana Reyes", phone: "555-0101")
    static let courier = AppUser(id: "user-courier-1", role: .courier, name: "Ben Cruz", phone: "555-0202")
    static let otherCustomer = AppUser(id: "user-customer-2", role: .customer, name: "Carla Lim", phone: "555-0303")

    static let accounts: [(email: String, password: String, user: AppUser)] = [
        ("customer@demo.test", demoPassword, customer),
        ("courier@demo.test", demoPassword, courier),
        ("carla@demo.test", demoPassword, otherCustomer),
    ]

    static let stores: [Store] = [
        Store(id: "store-burger", name: "Burger Barn", address: Address(line: "12 Main St"), isOpen: true, deliveryFee: 299,
              cuisine: "Burgers", deliveryMinutes: 25, tagline: "Smash burgers, fries and shakes", isFeatured: true),
        Store(id: "store-noodle", name: "Noodle House", address: Address(line: "48 Market Ave"), isOpen: true, deliveryFee: 199,
              cuisine: "Noodles", deliveryMinutes: 30, tagline: "Ramen, pho and dumplings"),
        Store(id: "store-bakery", name: "Corner Bakery", address: Address(line: "3 Elm Rd"), isOpen: true, deliveryFee: 149,
              cuisine: "Bakery", deliveryMinutes: 20, tagline: "Fresh bread, pastries and coffee"),
        Store(id: "store-pizza", name: "Slice Society", address: Address(line: "77 Bay St"), isOpen: true, deliveryFee: 249,
              cuisine: "Pizza", deliveryMinutes: 35, tagline: "Wood-fired pizza by the slice or pie", isFeatured: true),
        Store(id: "store-bowls", name: "Green Bowl Co.", address: Address(line: "5 River Walk"), isOpen: true, deliveryFee: 199,
              cuisine: "Healthy", deliveryMinutes: 20, tagline: "Salads, grain bowls and juices"),
        Store(id: "store-chicken", name: "Crispy Coop", address: Address(line: "210 North Rd"), isOpen: true, deliveryFee: 0,
              cuisine: "Chicken", deliveryMinutes: 25, tagline: "Fried chicken, rice meals and sides", isFeatured: true),
        Store(id: "store-closed", name: "Late Night Tacos", address: Address(line: "90 Harbor Blvd"), isOpen: false, deliveryFee: 249,
              cuisine: "Mexican", deliveryMinutes: 30, tagline: "Tacos and burritos after dark"),
    ]

    static let menuItems: [MenuItem] =
        menu("store-burger", [
            ("burger-classic", "Burgers", "Classic Burger", 899, "Beef patty, cheddar, lettuce, tomato, house sauce", true, true),
            ("burger-cheese", "Burgers", "Double Cheeseburger", 1199, "Two smashed patties, double cheese, pickles, onions", true, true),
            ("burger-chicken", "Burgers", "Crispy Chicken Burger", 999, "Buttermilk chicken, slaw, spicy mayo", false, true),
            ("burger-fries", "Sides", "Fries", 349, "Skin-on fries with sea salt", true, true),
            ("burger-rings", "Sides", "Onion Rings", 449, "Beer-battered, with ranch dip", false, true),
            ("burger-shake", "Drinks", "Vanilla Shake", 499, "Thick shake with real vanilla", false, false),
            ("burger-cola", "Drinks", "Cola", 199, "330 ml can", false, true),
        ])
        + menu("store-noodle", [
            ("noodle-ramen", "Noodle Soups", "Shoyu Ramen", 1299, "Soy broth, chashu pork, egg, bamboo, scallion", true, true),
            ("noodle-pho", "Noodle Soups", "Beef Pho", 1349, "Slow-cooked beef broth, rice noodles, herbs", true, true),
            ("noodle-tantan", "Noodle Soups", "Spicy Tantanmen", 1399, "Sesame-chili broth, minced pork, bok choy", false, true),
            ("noodle-dumpling", "Small Plates", "Pork Dumplings (6)", 699, "Pan-fried, with black vinegar dip", true, true),
            ("noodle-bun", "Small Plates", "Pork Belly Bao (2)", 799, "Steamed buns, hoisin, cucumber", false, true),
            ("noodle-tea", "Drinks", "Iced Jasmine Tea", 299, "Lightly sweetened", false, true),
        ])
        + menu("store-bakery", [
            ("bakery-croissant", "Pastries", "Butter Croissant", 325, "Flaky, all-butter, baked this morning", true, true),
            ("bakery-pain", "Pastries", "Pain au Chocolat", 375, "Croissant dough with dark chocolate", false, true),
            ("bakery-sourdough", "Bread", "Sourdough Loaf", 799, "24-hour fermented country loaf", false, true),
            ("bakery-baguette", "Bread", "Baguette", 399, "Crisp crust, open crumb", false, true),
            ("bakery-coffee", "Coffee", "Latte", 450, "Double shot with steamed milk", true, true),
            ("bakery-americano", "Coffee", "Americano", 350, "Double shot with hot water", false, true),
        ])
        + menu("store-pizza", [
            ("pizza-margherita", "Pizzas", "Margherita", 1499, "Tomato, fior di latte, basil, olive oil", true, true),
            ("pizza-pepperoni", "Pizzas", "Pepperoni", 1699, "Tomato, mozzarella, spicy pepperoni", true, true),
            ("pizza-funghi", "Pizzas", "Funghi", 1599, "Mushrooms, garlic cream, thyme", false, true),
            ("pizza-garlic", "Sides", "Garlic Knots (6)", 599, "With marinara dip", false, true),
            ("pizza-caesar", "Sides", "Caesar Salad", 899, "Romaine, parmesan, croutons", false, false),
        ])
        + menu("store-bowls", [
            ("bowl-salmon", "Bowls", "Salmon Poke Bowl", 1499, "Salmon, rice, edamame, avocado, ponzu", true, true),
            ("bowl-chicken", "Bowls", "Chicken Quinoa Bowl", 1299, "Grilled chicken, quinoa, roasted veg, tahini", true, true),
            ("bowl-greens", "Salads", "Super Greens", 1099, "Kale, spinach, seeds, lemon dressing", false, true),
            ("bowl-juice", "Juices", "Green Juice", 599, "Apple, cucumber, celery, ginger", false, true),
        ])
        + menu("store-chicken", [
            ("chicken-2pc", "Chicken", "2-Piece Fried Chicken", 899, "Crispy, juicy, with gravy", true, true),
            ("chicken-wings", "Chicken", "Spicy Wings (6)", 799, "Tossed in house hot sauce", true, true),
            ("chicken-rice", "Rice Meals", "Chicken Rice Meal", 699, "1 piece chicken, rice, gravy", false, true),
            ("chicken-fries", "Sides", "Cajun Fries", 349, "Seasoned fries", false, true),
            ("chicken-iced-tea", "Drinks", "Iced Tea", 199, "House-brewed", false, true),
        ])
        + menu("store-closed", [
            ("taco-alpastor", "Tacos", "Al Pastor Taco", 399, "Pork, pineapple, onion, cilantro", true, true),
        ])

    private static func menu(
        _ storeID: String,
        _ rows: [(id: String, category: String, name: String, price: Int, details: String, popular: Bool, available: Bool)]
    ) -> [MenuItem] {
        rows.map {
            MenuItem(id: $0.id, storeID: storeID, name: $0.name, price: $0.price, isAvailable: $0.available,
                     category: $0.category, details: $0.details, isPopular: $0.popular)
        }
    }

    /// Two open orders for couriers to see and one finished delivery for history.
    static func orders(now: Date = Date()) -> [Order] {
        func make(_ id: String, _ customer: AppUser, _ storeID: String, _ lines: [(String, Int)], _ address: String, minutesAgo: Double) -> Order {
            let store = stores.first { $0.id == storeID }!
            let items = lines.map { itemID, qty in OrderItem(menuItems.first { $0.id == itemID }!, quantity: qty) }
            return try! Order.new(
                id: id, customer: customer, store: store, items: items,
                deliveryAddress: Address(line: address), now: now.addingTimeInterval(-minutesAgo * 60)
            )
        }

        let placed1 = make("order-1001", customer, "store-burger", [("burger-classic", 2), ("burger-fries", 1)], "221 Oak St, Apt 4", minutesAgo: 6)
        let placed2 = make("order-1002", otherCustomer, "store-noodle", [("noodle-ramen", 1), ("noodle-dumpling", 2)], "7 Pine Ct", minutesAgo: 2)
        var delivered = make("order-0990", customer, "store-bakery", [("bakery-croissant", 3), ("bakery-coffee", 2)], "221 Oak St, Apt 4", minutesAgo: 60 * 26)
        delivered.courierID = courier.id
        delivered.courierName = courier.name
        delivered.courierPhone = courier.phone
        delivered.status = .delivered
        delivered.updatedAt = delivered.createdAt.addingTimeInterval(35 * 60)
        return [placed1, placed2, delivered]
    }
}
