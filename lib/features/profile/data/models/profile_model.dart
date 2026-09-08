class ProfileModel {
  const ProfileModel({
    this.name,
    this.phone,
    this.retailerId,
    this.darkstoreAddress,
    this.city,
    this.state,
    this.payableBalance = 0,
    this.darkstoreCommissionPercent = 0,
    this.totalOrders = 0,
    this.delivered = 0,
    this.pending = 0,
    this.cancelled = 0,
    this.gramikPlatformOrders = 0,
    this.counterSalesOrders = 0,
    this.totalCommission = 0,
    this.gramikPlatformCommission = 0,
    this.counterSalesCommission = 0,
    this.revenueEarnedByPlatform = 0,
  });

  final String? name;
  final String? phone;
  final String? retailerId;
  final String? darkstoreAddress;
  final String? city;
  final String? state;
  final num payableBalance;
  final num darkstoreCommissionPercent;
  final int totalOrders;
  final int delivered;
  final int pending;
  final int cancelled;
  final int gramikPlatformOrders;
  final int counterSalesOrders;
  final num totalCommission;
  final num gramikPlatformCommission;
  final num counterSalesCommission;
  final num revenueEarnedByPlatform;

  String get displayAddress {
    final direct = (darkstoreAddress ?? '').trim();
    if (direct.isNotEmpty) return direct;
    return [city, state]
        .where((e) => (e ?? '').trim().isNotEmpty && e != 'Other')
        .join(', ');
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    num asNum(dynamic v) {
      if (v is num) return v;
      return num.tryParse('$v') ?? 0;
    }

    return ProfileModel(
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      retailerId: json['retailer_id']?.toString(),
      darkstoreAddress: json['darkstore_address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      payableBalance: asNum(json['payable_balance']),
      darkstoreCommissionPercent: asNum(
        json['darkstore_commission_percent'] ??
            json['dark_store_commission_percentage'],
      ),
      totalOrders: asInt(json['total_orders_combined'] ?? json['total_orders']),
      delivered: asInt(json['delivered']),
      pending: asInt(json['pending']),
      cancelled: asInt(json['cancelled']),
      gramikPlatformOrders: asInt(json['gramik_platform_orders']),
      counterSalesOrders: asInt(json['counter_sales_orders']),
      totalCommission: asNum(json['total_commission']),
      gramikPlatformCommission: asNum(json['gramik_platform_commission']),
      counterSalesCommission: asNum(json['counter_sales_commission']),
      revenueEarnedByPlatform: asNum(json['revenue_earned_by_platform']),
    );
  }
}
