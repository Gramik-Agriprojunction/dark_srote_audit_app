import '../../data/models/business_location_model.dart';

/// Picks the store to use: saved preference if valid, else the only location.
int? resolvePreferredStoreId(
  List<BusinessLocationModel> locations,
  int? preferredStoreId,
) {
  if (locations.isEmpty) return null;

  if (preferredStoreId != null &&
      locations.any((location) => location.id == preferredStoreId)) {
    return preferredStoreId;
  }

  if (locations.length == 1) return locations.first.id;

  return null;
}
