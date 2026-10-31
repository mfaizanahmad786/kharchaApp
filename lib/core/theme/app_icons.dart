import 'package:flutter/material.dart';

/// Icons are persisted by *name*, never by raw code point: constructing
/// `IconData` from a stored int would defeat Flutter's icon tree-shaking and
/// bloat the APK. This table is the single source of truth.
abstract final class AppIcons {
  static const _map = <String, IconData>{
    'groceries': Icons.local_grocery_store_rounded,
    'clothing': Icons.checkroom_rounded,
    'cafe': Icons.local_cafe_rounded,
    'restaurant': Icons.restaurant_rounded,
    'transport': Icons.directions_bus_filled_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'car': Icons.directions_car_filled_rounded,
    'home': Icons.home_rounded,
    'rent': Icons.vpn_key_rounded,
    'bills': Icons.receipt_long_rounded,
    'phone': Icons.smartphone_rounded,
    'internet': Icons.wifi_rounded,
    'health': Icons.favorite_rounded,
    'medicine': Icons.medical_services_rounded,
    'education': Icons.school_rounded,
    'books': Icons.menu_book_rounded,
    'entertainment': Icons.movie_rounded,
    'gaming': Icons.sports_esports_rounded,
    'fitness': Icons.fitness_center_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'vacation': Icons.beach_access_rounded,
    'gift': Icons.card_giftcard_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'pets': Icons.pets_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'savings': Icons.savings_rounded,
    'salary': Icons.payments_rounded,
    'business': Icons.storefront_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'investment': Icons.trending_up_rounded,
    'bonus': Icons.emoji_events_rounded,
    'refund': Icons.replay_rounded,
    'interest': Icons.account_balance_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'cash': Icons.payments_outlined,
    'card': Icons.credit_card_rounded,
    'bank': Icons.account_balance_rounded,
    'other': Icons.more_horiz_rounded,
  };

  static const fallback = Icons.category_rounded;

  static IconData byName(String? name) => _map[name] ?? fallback;

  static List<String> get names => _map.keys.toList(growable: false);
}
