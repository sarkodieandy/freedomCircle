import 'model_helpers.dart';

class HelperProfile {
  const HelperProfile({
    required this.name,
    required this.photoUrl,
    required this.organization,
    required this.focusAreas,
    required this.rating,
    required this.price,
    required this.availability,
    required this.bio,
    required this.languages,
    required this.isFreeAvailable,
  });

  final String name;
  final String photoUrl;
  final String organization;
  final List<String> focusAreas;
  final double rating;
  final String price;
  final String availability;
  final String bio;
  final List<String> languages;
  final bool isFreeAvailable;

  factory HelperProfile.fromMap(JsonMap map) {
    final price = readNum(map, 'session_price');
    final currency = readString(map, 'currency', fallback: 'GHS');

    return HelperProfile(
      name: readString(
        map,
        'display_name',
        fallback: readString(map, 'name', fallback: 'FreedomCircle helper'),
      ),
      photoUrl: readString(
        map,
        'profile_photo_url',
        fallback: readString(map, 'photo_url'),
      ),
      organization: readString(map, 'organization', fallback: 'FreedomCircle'),
      focusAreas: readStringList(map, 'focus_areas'),
      rating: readDouble(map, 'rating'),
      price: price == 0 ? 'Free intro' : '$currency $price/session',
      availability: readString(map, 'availability', fallback: 'Check schedule'),
      bio: readString(map, 'bio'),
      languages: readStringList(map, 'languages'),
      isFreeAvailable: price == 0,
    );
  }
}
