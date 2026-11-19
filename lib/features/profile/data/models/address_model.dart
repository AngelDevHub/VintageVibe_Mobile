class AddressModel {
  final int? id;
  final String fullName;
  final String addressLine1;
  final String city;
  final String postalCode;
  final String country;
  final String phoneNumber;

  AddressModel({
    this.id,
    required this.fullName,
    required this.addressLine1,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.phoneNumber,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'],
        fullName: json['fullName'] ?? '',
        addressLine1: json['addressLine1'] ?? '',
        city: json['city'] ?? '',
        postalCode: json['postalCode'] ?? '',
        country: json['country'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'addressLine1': addressLine1,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'phoneNumber': phoneNumber,
      };
}
