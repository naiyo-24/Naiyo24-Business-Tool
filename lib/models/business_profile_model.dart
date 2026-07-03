class BusinessProfileModel {
  final String businessName;
  final String brandName;
  final String website;
  final String phone;
  final String country;
  final String currency;
  final String gstNumber;
  final String address;

  const BusinessProfileModel({
    this.businessName = '',
    this.brandName = '',
    this.website = '',
    this.phone = '',
    this.country = '',
    this.currency = '',
    this.gstNumber = '',
    this.address = '',
  });

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileModel(
      businessName: json['businessName'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      website: json['website'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      country: json['country'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      gstNumber: json['gstNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'brandName': brandName,
      'website': website,
      'phone': phone,
      'country': country,
      'currency': currency,
      'gstNumber': gstNumber,
      'address': address,
    };
  }

  BusinessProfileModel copyWith({
    String? businessName,
    String? brandName,
    String? website,
    String? phone,
    String? country,
    String? currency,
    String? gstNumber,
    String? address,
  }) {
    return BusinessProfileModel(
      businessName: businessName ?? this.businessName,
      brandName: brandName ?? this.brandName,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
    );
  }
}
