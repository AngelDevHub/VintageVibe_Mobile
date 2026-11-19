/// VintageVibe Mobile — API Endpoints
/// All REST endpoints mirroring the Spring Boot backend.

class ApiEndpoints {
  ApiEndpoints._();

  // ==================== Auth ====================
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';

  // ==================== Products ====================
  static const String products = '/products';
  static String productById(int id) => '/products/$id';
  static String productBySlug(String slug) => '/products/slug/$slug';

  // ==================== Categories ====================
  static const String categories = '/categories';
  static String categoryById(int id) => '/categories/$id';

  // ==================== Brands ====================
  static const String brands = '/brands';

  // ==================== Product Conditions ====================
  static const String conditions = '/conditions';

  // ==================== Cart ====================
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItem(int itemId) => '/cart/items/$itemId';

  // ==================== Orders ====================
  static const String checkout = '/orders/checkout';
  static const String orders = '/orders';
  static String orderById(int id) => '/orders/$id';

  // ==================== Account ====================
  static const String account = '/account';
  static const String accountPassword = '/account/password';

  // ==================== Addresses ====================
  static const String addresses = '/addresses';
  static String addressById(int id) => '/addresses/$id';

  // ==================== Reviews ====================
  static const String reviews = '/reviews';
  static String reviewsByProduct(int productId) => '/reviews/product/$productId';

  // ==================== C2C Listings ====================
  static const String c2cListings = '/c2c/listings';
  static const String c2cMyListings = '/c2c/listings/mine';
  static String c2cSellerListings(int sellerId) => '/c2c/listings/seller/$sellerId';
  static String c2cListing(int id) => '/c2c/listings/$id';

  // ==================== Coupons ====================
  static const String coupons = '/coupons';
  static String couponValidate(String code) => '/coupons/validate/$code';

  // ==================== Wearable Notifications (Práctica 2) ====================
  static const String wearableRegisterToken = '/notifications/wearable/register-token';
  static const String wearableSimulateSale = '/notifications/wearable/simulate-sale';
  static const String wearablePoll = '/notifications/wearable/poll';
}
