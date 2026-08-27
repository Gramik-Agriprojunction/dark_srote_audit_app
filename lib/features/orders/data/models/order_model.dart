class OrderShippingAddressModel {
  const OrderShippingAddressModel({
    this.name,
    this.fullName,
    this.city,
    this.address,
    this.phone,
    this.alternatePhone,
    this.pincode,
  });

  final String? name;
  final String? fullName;
  final String? city;
  final String? address;
  final String? phone;
  final String? alternatePhone;
  final String? pincode;

  factory OrderShippingAddressModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OrderShippingAddressModel();
    return OrderShippingAddressModel(
      name: json['name']?.toString(),
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString() ?? json['mobile']?.toString(),
      alternatePhone:
          json['alternate_phone']?.toString() ?? json['alternatePhone']?.toString(),
      pincode: json['pincode']?.toString(),
    );
  }

  String get displayName => (name ?? fullName ?? '').trim();

  String get fullAddress {
    return [address, pincode]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .join(', ');
  }
}

class OrderDeliveryPartnerModel {
  const OrderDeliveryPartnerModel({this.name, this.phone});

  final String? name;
  final String? phone;

  factory OrderDeliveryPartnerModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OrderDeliveryPartnerModel();
    return OrderDeliveryPartnerModel(
      name: json['name']?.toString(),
      phone: json['phone']?.toString() ?? json['mobile']?.toString(),
    );
  }
}

class OrderProductLineModel {
  const OrderProductLineModel({
    required this.name,
    required this.quantity,
    this.price,
    this.thumbnailImg,
    this.variantSku,
  });

  final String name;
  final int quantity;
  final double? price;
  final String? thumbnailImg;
  final String? variantSku;

  factory OrderProductLineModel.fromJson(Map<String, dynamic> json) {
    final priceRaw = json['price'];
    return OrderProductLineModel(
      name: (json['name'] ?? '').toString(),
      quantity: int.tryParse('${json['quantity']}') ?? 0,
      price: priceRaw == null ? null : double.tryParse('$priceRaw'),
      thumbnailImg: json['thumbnail_img']?.toString(),
      variantSku: json['variant_sku']?.toString(),
    );
  }
}

class OrderListItemModel {
  const OrderListItemModel({
    required this.id,
    required this.code,
    required this.grandTotal,
    required this.createdAt,
    required this.orderStatus,
    required this.paymentType,
    this.paymentStatus,
    this.sumQuantity = 0,
    this.firstProductImage,
    this.shippingAddress = const OrderShippingAddressModel(),
    this.products = const [],
  });

  final int id;
  final String code;
  final double grandTotal;
  final String createdAt;
  final String orderStatus;
  final String paymentType;
  final String? paymentStatus;
  final int sumQuantity;
  final String? firstProductImage;
  final OrderShippingAddressModel shippingAddress;
  final List<OrderProductLineModel> products;

  factory OrderListItemModel.fromJson(Map<String, dynamic> json) {
    final productsRaw = json['products'];
    return OrderListItemModel(
      id: int.tryParse('${json['id']}') ?? 0,
      code: (json['code'] ?? '').toString(),
      grandTotal: double.tryParse('${json['grand_total']}') ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      orderStatus: (json['order_status'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? 'cod').toString(),
      paymentStatus: json['payment_status']?.toString(),
      sumQuantity: int.tryParse('${json['sum_quantity']}') ?? 0,
      firstProductImage: json['first_product_image']?.toString(),
      shippingAddress: OrderShippingAddressModel.fromJson(
        json['shipping_address'] as Map<String, dynamic>?,
      ),
      products: productsRaw is List
          ? productsRaw
              .whereType<Map<String, dynamic>>()
              .map(OrderProductLineModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class OrderDetailModel {
  const OrderDetailModel({
    required this.id,
    required this.code,
    required this.grandTotal,
    required this.createdAt,
    required this.orderStatus,
    required this.paymentType,
    this.orderType = 'gramik',
    this.paymentStatus,
    this.subtotal = 0,
    this.discount = 0,
    this.shippingCost = 0,
    this.sumQuantity = 0,
    this.pickReady = false,
    this.markStatus,
    this.scheduleDate,
    this.selectedDeliveryDate,
    this.transactionId,
    this.utr,
    this.otp,
    this.deliverOtp,
    this.pickupOtp,
    this.shippingAddress = const OrderShippingAddressModel(),
    this.deliveryPartner = const OrderDeliveryPartnerModel(),
    this.products = const [],
  });

  final int id;
  final String code;
  final double grandTotal;
  final String createdAt;
  final String orderStatus;
  final String paymentType;
  final String orderType;
  final String? paymentStatus;
  final double subtotal;
  final double discount;
  final double shippingCost;
  final int sumQuantity;
  final bool pickReady;
  final String? markStatus;
  final String? scheduleDate;
  final String? selectedDeliveryDate;
  final String? transactionId;
  final String? utr;
  final String? otp;
  final String? deliverOtp;
  final String? pickupOtp;
  final OrderShippingAddressModel shippingAddress;
  final OrderDeliveryPartnerModel deliveryPartner;
  final List<OrderProductLineModel> products;

  bool get isCounterSale => orderType.toLowerCase() == 'counter_sale';

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final productsRaw = json['products'];
    return OrderDetailModel(
      id: int.tryParse('${json['id']}') ?? 0,
      code: (json['code'] ?? '').toString(),
      grandTotal: double.tryParse('${json['grand_total']}') ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      orderStatus: (json['order_status'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? 'cod').toString(),
      orderType: (json['orderType'] ?? json['order_type'] ?? 'gramik').toString(),
      paymentStatus: json['payment_status']?.toString(),
      subtotal: double.tryParse('${json['subtotal']}') ?? 0,
      discount: double.tryParse('${json['discount']}') ?? 0,
      shippingCost: double.tryParse('${json['shipping_cost']}') ?? 0,
      sumQuantity: int.tryParse('${json['sum_quantity']}') ?? 0,
      pickReady: json['pick_ready'] == true || json['is_ready_to_pick'] == true,
      markStatus: json['mark_status']?.toString(),
      scheduleDate: json['schedule_date']?.toString(),
      selectedDeliveryDate: json['selected_delivery_date']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      utr: json['utr']?.toString(),
      otp: json['otp']?.toString(),
      deliverOtp: json['deliver_otp']?.toString(),
      pickupOtp: json['pickup_otp']?.toString() ?? json['bulk_pickup_otp']?.toString(),
      shippingAddress: OrderShippingAddressModel.fromJson(
        json['shipping_address'] as Map<String, dynamic>?,
      ),
      deliveryPartner: OrderDeliveryPartnerModel.fromJson(
        json['delivery_partner'] as Map<String, dynamic>?,
      ),
      products: productsRaw is List
          ? productsRaw
              .whereType<Map<String, dynamic>>()
              .map(OrderProductLineModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class CancelReasonModel {
  const CancelReasonModel({required this.reason, this.id});

  final int? id;
  final String reason;

  factory CancelReasonModel.fromJson(dynamic json, int index) {
    if (json is String) {
      return CancelReasonModel(id: index + 1, reason: json);
    }
    if (json is Map<String, dynamic>) {
      return CancelReasonModel(
        id: int.tryParse('${json['id'] ?? json['reason_id'] ?? index + 1}'),
        reason: (json['reason'] ?? json['label'] ?? json['name'] ?? '').toString(),
      );
    }
    return CancelReasonModel(id: index + 1, reason: '');
  }
}

class OrderListStatsModel {
  const OrderListStatsModel({
    this.totalOrders = 0,
    this.pending = 0,
    this.totalValue = 0,
    this.notificationCount = 0,
  });

  final int totalOrders;
  final int pending;
  final double totalValue;
  final int notificationCount;

  factory OrderListStatsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OrderListStatsModel();
    return OrderListStatsModel(
      totalOrders: int.tryParse('${json['total_order']}') ?? 0,
      pending: int.tryParse('${json['pending']}') ?? 0,
      totalValue: double.tryParse('${json['total_value']}') ?? 0,
      notificationCount: int.tryParse('${json['notification_count']}') ?? 0,
    );
  }
}

class OrderPaginationModel {
  const OrderPaginationModel({
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.from = 0,
    this.to = 0,
    this.hasNextPage = false,
  });

  final int currentPage;
  final int totalPages;
  final int total;
  final int from;
  final int to;
  final bool hasNextPage;

  factory OrderPaginationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OrderPaginationModel();
    final current = int.tryParse('${json['current_page']}') ?? 1;
    final totalPages = int.tryParse('${json['total_pages']}') ?? 1;
    return OrderPaginationModel(
      currentPage: current,
      totalPages: totalPages,
      total: int.tryParse('${json['total']}') ?? 0,
      from: int.tryParse('${json['from']}') ?? 0,
      to: int.tryParse('${json['to']}') ?? 0,
      hasNextPage: json['has_next_page'] == true || current < totalPages,
    );
  }
}

class OrderListResultModel {
  const OrderListResultModel({
    required this.orders,
    required this.stats,
    required this.pagination,
  });

  final List<OrderListItemModel> orders;
  final OrderListStatsModel stats;
  final OrderPaginationModel pagination;

  factory OrderListResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final ordersRaw = data?['order'];
    return OrderListResultModel(
      orders: ordersRaw is List
          ? ordersRaw
              .whereType<Map<String, dynamic>>()
              .map(OrderListItemModel.fromJson)
              .toList()
          : const [],
      stats: OrderListStatsModel.fromJson(
        json['count'] as Map<String, dynamic>?,
      ),
      pagination: OrderPaginationModel.fromJson(
        json['pagination'] as Map<String, dynamic>?,
      ),
    );
  }
}
