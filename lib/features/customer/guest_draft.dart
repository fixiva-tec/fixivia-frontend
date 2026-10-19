import '../../api/client.dart';

/// A booking assembled by a guest, submitted right after login.
///
/// Guests walk the same 4-step flow as customers but carry their address
/// as typed text (no saved addresses without an account). The landing page
/// holds the draft across the auth gate and submits it once a token exists.
class GuestDraft {
  const GuestDraft({
    required this.categoryId,
    required this.issueIds,
    required this.serviceDate,
    required this.slot,
    required this.addressLine,
    required this.pincode,
  });

  final String categoryId;
  final List<String> issueIds;

  /// `YYYY-MM-DD`.
  final String serviceDate;
  final String slot;
  final String addressLine;
  final String pincode;

  Map<String, dynamic> bookingBody(String addressId) => {
    'address_id': addressId,
    'category_id': categoryId,
    'issue_template_ids': issueIds,
    'service_date': serviceDate,
    'slot': slot,
  };
}

/// Creates the guest's address, then posts the booking. Requires a token.
Future<Map<String, dynamic>> submitGuestDraft(
  ApiClient api,
  GuestDraft draft,
) async {
  final addr =
      await api.post('/v1/addresses', {
            'label': 'home',
            'line1': draft.addressLine,
            'pincode': draft.pincode,
            'is_default': true,
          })
          as Map<String, dynamic>;
  final booking = await api.post(
    '/v1/bookings',
    draft.bookingBody(addr['id'] as String),
  );
  return booking as Map<String, dynamic>;
}
