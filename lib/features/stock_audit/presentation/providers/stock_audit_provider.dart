import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/business_location_model.dart';
import '../../data/models/product_model.dart';
import '../../data/stock_audit_repository.dart';

class StockAuditState {
  const StockAuditState({
    this.locations = const [],
    this.selectedLocationId,
    this.products = const [],
    this.searchQuery = '',
    this.isLoadingLocations = false,
    this.isLoadingProducts = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.qtyDrafts = const {},
    this.emptyDraftVariantIds = const {},
  });

  final List<BusinessLocationModel> locations;
  final int? selectedLocationId;
  final List<ProductModel> products;
  final String searchQuery;
  final bool isLoadingLocations;
  final bool isLoadingProducts;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final Map<int, int> qtyDrafts;
  final Set<int> emptyDraftVariantIds;

  bool get showProducts => selectedLocationId != null;

  List<ProductModel> get filteredProducts {
    final term = searchQuery.trim().toLowerCase();
    if (term.isEmpty) return products;

    return products
        .map((product) {
          final productName = product.name.toLowerCase();
          final matchingVariants = product.variants.where((variant) {
            final variantName = variant.variantName.toLowerCase();
            final sku = variant.sku.toLowerCase();
            return productName.contains(term) ||
                variantName.contains(term) ||
                sku.contains(term);
          }).toList();

          if (productName.contains(term)) return product;
          if (matchingVariants.isEmpty) return null;
          return product.copyWith(variants: matchingVariants);
        })
        .whereType<ProductModel>()
        .toList();
  }

  StockAuditState copyWith({
    List<BusinessLocationModel>? locations,
    int? selectedLocationId,
    bool clearSelectedLocation = false,
    List<ProductModel>? products,
    String? searchQuery,
    bool? isLoadingLocations,
    bool? isLoadingProducts,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearMessages = false,
    Map<int, int>? qtyDrafts,
    Set<int>? emptyDraftVariantIds,
    bool clearDrafts = false,
  }) {
    return StockAuditState(
      locations: locations ?? this.locations,
      selectedLocationId: clearSelectedLocation
          ? null
          : (selectedLocationId ?? this.selectedLocationId),
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingLocations: isLoadingLocations ?? this.isLoadingLocations,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      isSaving: isSaving ?? this.isSaving,
      error: clearMessages ? null : (error ?? this.error),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
      qtyDrafts: clearDrafts ? const {} : (qtyDrafts ?? this.qtyDrafts),
      emptyDraftVariantIds: clearDrafts
          ? const {}
          : (emptyDraftVariantIds ?? this.emptyDraftVariantIds),
    );
  }
}

final stockAuditControllerProvider =
    StateNotifierProvider<StockAuditController, StockAuditState>((ref) {
      return StockAuditController(ref.watch(stockAuditRepositoryProvider));
    });

class StockAuditController extends StateNotifier<StockAuditState> {
  StockAuditController(this._repository) : super(const StockAuditState());

  final StockAuditRepository _repository;

  Future<void> loadLocations({int? preferredStoreId}) async {
    state = state.copyWith(isLoadingLocations: true, clearMessages: true);
    try {
      final locations = await _repository.getBusinessLocations();
      int? selectedId;
      if (preferredStoreId != null &&
          locations.any((location) => location.id == preferredStoreId)) {
        selectedId = preferredStoreId;
      }
      state = state.copyWith(
        locations: locations,
        isLoadingLocations: false,
        selectedLocationId: selectedId,
      );
      if (selectedId != null) {
        await loadProducts(selectedId);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingLocations: false, error: e.message);
    }
  }

  Future<void> selectLocation(int? locationId) async {
    state = state.copyWith(
      clearSelectedLocation: locationId == null,
      selectedLocationId: locationId,
      products: const [],
      searchQuery: '',
      clearDrafts: true,
      clearMessages: true,
    );
    if (locationId != null) {
      await loadProducts(locationId);
    }
  }

  Future<void> loadProducts(int locationId) async {
    state = state.copyWith(
      isLoadingProducts: true,
      clearMessages: true,
      clearDrafts: true,
    );
    try {
      final products = await _repository.getLocationProducts(locationId);
      state = state.copyWith(products: products, isLoadingProducts: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        error: e.message,
        products: const [],
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setQtyDraft(int variantId, int? qty, {bool emptyInput = false}) {
    final drafts = Map<int, int>.from(state.qtyDrafts);
    final emptyIds = Set<int>.from(state.emptyDraftVariantIds);

    if (emptyInput) {
      drafts.remove(variantId);
      emptyIds.add(variantId);
    } else if (qty == null) {
      drafts.remove(variantId);
      emptyIds.remove(variantId);
    } else {
      drafts[variantId] = qty;
      emptyIds.remove(variantId);
    }

    state = state.copyWith(
      qtyDrafts: drafts,
      emptyDraftVariantIds: emptyIds,
      clearMessages: true,
    );
  }

  void clearQtyDraft(int variantId) {
    final drafts = Map<int, int>.from(state.qtyDrafts)..remove(variantId);
    final emptyIds = Set<int>.from(state.emptyDraftVariantIds)
      ..remove(variantId);
    state = state.copyWith(qtyDrafts: drafts, emptyDraftVariantIds: emptyIds);
  }

  ProductVariantModel? findVariant(int variantId) {
    for (final product in state.products) {
      for (final variant in product.variants) {
        if (variant.id == variantId) return variant;
      }
    }
    return null;
  }

  void _applySavedItems(List<BulkSaveItemModel> items) {
    if (items.isEmpty) return;
    final products = state.products.map((product) {
      final variants = product.variants.map((variant) {
        final saved = items
            .where((item) => item.variantId == variant.id)
            .firstOrNull;
        if (saved == null) return variant;
        return variant.copyWith(
          auditQty: saved.qty,
          auditUpdatedAt: saved.updatedAt ?? DateTime.now().toUtc(),
        );
      }).toList();
      return product.copyWith(variants: variants);
    }).toList();

    state = state.copyWith(products: products, clearDrafts: true);
  }

  Future<bool> saveSingleVariant({
    required int productId,
    required int variantId,
    required int qty,
  }) async {
    final locationId = state.selectedLocationId;
    if (locationId == null) return false;

    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final result = await _repository.saveBulk(
        businessLocationId: locationId,
        items: [
          {'productId': productId, 'variantId': variantId, 'qty': qty},
        ],
      );
      if (result.items.isNotEmpty) {
        _applySavedItems(result.items);
      } else {
        _applySavedItems([
          BulkSaveItemModel(
            productId: productId,
            variantId: variantId,
            qty: qty,
            updatedAt: DateTime.now().toUtc(),
          ),
        ]);
      }
      state = state.copyWith(
        isSaving: false,
        successMessage: result.updated > 0
            ? 'Successfully updated.'
            : 'Successfully saved.',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }

  Future<bool> saveAllChanged() async {
    final locationId = state.selectedLocationId;
    if (locationId == null) {
      state = state.copyWith(error: 'Business location select karein.');
      return false;
    }

    final items = <Map<String, dynamic>>[];
    for (final product in state.products) {
      for (final variant in product.variants) {
        final draft = state.qtyDrafts[variant.id];
        final hasDraft = state.qtyDrafts.containsKey(variant.id);
        if (!hasDraft || draft == null) continue;
        items.add({
          'productId': product.id,
          'variantId': variant.id,
          'qty': draft,
        });
      }
    }

    if (items.isEmpty) {
      state = state.copyWith(
        error: 'Kam se kam ek variant ki qty update karein.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final result = await _repository.saveBulk(
        businessLocationId: locationId,
        items: items,
      );
      if (result.items.isNotEmpty) {
        _applySavedItems(result.items);
      }
      state = state.copyWith(
        isSaving: false,
        successMessage: result.updated > 0
            ? 'Successfully updated.'
            : 'Successfully saved.',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }

  Future<bool> saveComment({
    required int productId,
    required int variantId,
    required String comment,
  }) async {
    final locationId = state.selectedLocationId;
    if (locationId == null) return false;

    try {
      await _repository.saveComment(
        businessLocationId: locationId,
        productId: productId,
        variantId: variantId,
        comment: comment,
      );

      final products = state.products.map((product) {
        if (product.id != productId) return product;
        final variants = product.variants.map((variant) {
          if (variant.id != variantId) return variant;
          return variant.copyWith(auditComment: comment);
        }).toList();
        return product.copyWith(variants: variants);
      }).toList();

      state = state.copyWith(
        products: products,
        successMessage: 'Successfully saved.',
        clearMessages: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
