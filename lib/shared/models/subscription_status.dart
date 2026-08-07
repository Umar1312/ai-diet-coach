enum SubscriptionState {
  free,
  trialing,
  active,
  gracePeriod,
  billingIssue,
  expired;

  static SubscriptionState fromString(String value) {
    switch (value) {
      case 'trialing':
        return SubscriptionState.trialing;
      case 'active':
        return SubscriptionState.active;
      case 'grace_period':
        return SubscriptionState.gracePeriod;
      case 'billing_issue':
        return SubscriptionState.billingIssue;
      case 'expired':
        return SubscriptionState.expired;
      default:
        return SubscriptionState.free;
    }
  }

  String get apiValue {
    switch (this) {
      case SubscriptionState.free:
        return 'free';
      case SubscriptionState.trialing:
        return 'trialing';
      case SubscriptionState.active:
        return 'active';
      case SubscriptionState.gracePeriod:
        return 'grace_period';
      case SubscriptionState.billingIssue:
        return 'billing_issue';
      case SubscriptionState.expired:
        return 'expired';
    }
  }
}

class SubscriptionStatus {
  final String appUserId;
  final String entitlementId;
  final bool isEntitled;
  final SubscriptionState status;
  final String? productId;
  final String? periodType;
  final String? store;
  final String? environment;
  final bool willRenew;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;
  final DateTime syncedAt;

  const SubscriptionStatus({
    required this.appUserId,
    required this.entitlementId,
    required this.isEntitled,
    required this.status,
    required this.willRenew,
    required this.syncedAt,
    this.productId,
    this.periodType,
    this.store,
    this.environment,
    this.purchasedAt,
    this.expiresAt,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      appUserId: json['app_user_id'] as String,
      entitlementId: json['entitlement_id'] as String,
      isEntitled: json['is_entitled'] as bool,
      status: SubscriptionState.fromString(json['status'] as String? ?? ''),
      productId: json['product_id'] as String?,
      periodType: json['period_type'] as String?,
      store: json['store'] as String?,
      environment: json['environment'] as String?,
      willRenew: json['will_renew'] as bool? ?? false,
      purchasedAt: _parseDate(json['purchased_at']),
      expiresAt: _parseDate(json['expires_at']),
      syncedAt: _parseDate(json['synced_at']) ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_user_id': appUserId,
      'entitlement_id': entitlementId,
      'is_entitled': isEntitled,
      'status': status.apiValue,
      'product_id': productId,
      'period_type': periodType,
      'store': store,
      'environment': environment,
      'will_renew': willRenew,
      'purchased_at': purchasedAt?.toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'synced_at': syncedAt.toUtc().toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
