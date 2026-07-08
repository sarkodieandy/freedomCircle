import 'model_helpers.dart';

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    this.logoUrl,
    this.coverUrl,
    this.description,
    this.country,
    this.city,
  });

  final String id;
  final String name;
  final String slug;
  final String status;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final String? logoUrl;
  final String? coverUrl;
  final String? description;
  final String? country;
  final String? city;

  factory Organization.fromMap(JsonMap map) {
    return Organization(
      id: readString(map, 'id'),
      name: readString(map, 'name'),
      slug: readString(map, 'slug'),
      status: readString(map, 'status', fallback: 'active'),
      subscriptionPlan: readString(map, 'subscription_plan', fallback: 'free'),
      subscriptionStatus: readString(
        map,
        'subscription_status',
        fallback: 'active',
      ),
      logoUrl: readNullableString(map, 'logo_url'),
      coverUrl: readNullableString(map, 'cover_url'),
      description: readNullableString(map, 'description'),
      country: readNullableString(map, 'country'),
      city: readNullableString(map, 'city'),
    );
  }
}
