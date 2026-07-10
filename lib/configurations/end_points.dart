class ApiEndPoints {
  static const String kLogin = "sale-user/login";
  static const String kWarehouseManagerLogin = "warehouse-manager/login";

  /// warehouse-manager/logout  →  clears activeDeviceId on the backend
  static const String kWarehouseManagerLogout = "warehouse-manager/logout";

  /// warehouse-manager/force-login  →  logs out the other active device and
  /// logs in on this one. Used when login returns ALREADY_LOGGED_IN.
  static const String kWarehouseManagerForceLogin = "warehouse-manager/force-login";
  static const String kGetRetailers = "retailer/city/";
  static const String kUpdateRetailerLocation = "retailer/location/";
  static const String kUpdateWholesalerLocation = "wholesaler/location/";

  /// sale-user/location/{id}  →  update distributor's shopLocation lat/lng
  static const String kUpdateDistributorLocation = "sale-user/location/";

  /// sale-user/register  →  register a new distributor (sales user)
  static const String kRegisterDistributor = "sale-user/register";

  static const String kGetCategories = "category/";

  static const String kGetProducts = "product";
  static const String kGetProductsByBrand = "product/brand/";

  static const String kGetOrders = "order/sale-person/status/";
  static const String kUpdateOrderStatus = "order/updatestatus/";
  static const String kAddOrder = "order/add";

  static const String kGetBrands = "brand/category/";
  static const String kGetAllBrands = "brand";
  static const String kGetBrandDetail = "brand/";

  /// category/brand/{brandId}  →  categories belonging to a specific brand
  static const String kGetCategoriesByBrand = "category/brand/";

  /// product/category/{categoryId}  →  products in a specific category
  static const String kGetProductsByCategory = "product/category/";
  static const String kGetStats = "sale-user/sales/";
  static const String kGetTargets = "targets/salesperson/";
  static const String kGetTargetsOrderbooker = "targets/orderbooker/"; // ← ADDED
  static const String kGetTermsCondition = "setting/termsandconditions";
  static const String kGetPrivacyPolicy = "setting/privacypolicy";
  static const String kRegister = "user/register";
  static const String kGetNews = "news/category/";
  static const String kGetSigma = "news/category/";
  static const String kGetBookmarkNews = "news/bookmarks/all";
  static const String kSearchNews = "news/search/";
  static const String kGetReports = "report";
  static const String kGetFAQs = "faq";
  static const String kGetHomeData = "category/home-data";
  static const String kReportNews = "news/report";
  static const String kAddBookMark = "news/bookmarks/update";
  static const String kAddSigmaBookMark = "sigma/favourites";
  static const String kGetComments = "comment/";
  static const String kAddComment = "comment/add";
  static const String kAddSigmaComment = "sigma-comment/add";
  static const String kGetSettings = "setting";
  static const String kGetVideo = "youtube";
  static const String kGetSigmaListing = "sigma";
  static const String kGetFavoriteSigma = "sigma/favourites";
  static const String kGetStudyModeSigma = "sigma";
  static const String kAddSigma = "sigma/add";
  static const String kUpdateSigma = "sigma/update";
  static const String kGetSigmaComment = "sigma-comment/";
  static const String kGetAllNews = "news?page=1&limit=1000";
  static const String kGetSigmaByNewsID = "sigma/news/";
  static const String kGetSigmaByCategoryID = "sigma/category/";
  static const String kDeleteSigma = "sigma/delete/";
  static const String kSearchSigma = "sigma/search/";
  static const String kAddLikeToSigma = "sigma/reaction";
  static const String kAddTemplate = "template/add";
  static const String kGetTemplates = "template/user";
  static const String kDeleteTemplate = "template/delete/";
  static const String kUpdateProfile = "user/update/";
  static const String kGetUserByID = "sale-user/";
  static const String kGetSigmaByUserID = "sigma/user";
  static const String kUpdateTimelineImage = "user/update/timelineimage";
  static const String kUpdateUserImage = "user/update/image";
  static const String kAddLikeToSigmaComment = "sigma-comment/like";
  static const String kAddReplyToSigma = "sigma-comment/reply";
  static const String kCheckIn = "attendance/add";
  static const String kCheckOut = "attendance/update";
  static const String kAddVisit = "visit/add";
  static const String kApplyCoupon = "coupons/validate-mobile";
  static const String kSendCoordinates = "tracking/ping";
  static const String kGetAllBanks = "bank/getall";
  static const String kAddRecovery = "payment/create";
  static const String kGetMyPayments = "payment/get-my-payment";
  static const String kAddWholesaler = "wholesaler/add";
  static const String kAddRetailer = "retailer/add";
  static const String kGetRetailer = "retailer/";
  static const String kGetWholesaler = "wholesaler/";

  /// warehouse-manager/update-profile-picture/{id}  →  update TSM profile photo
  static const String kUpdateWarehouseManagerProfilePicture = "warehouse-manager/update-profile-picture/";

  /// order-booker/update-profile-picture/{id}  →  update OrderBooker profile photo
  static const String kUpdateOrderBookerProfilePicture = "order-booker/update-profile-picture/";


  /// zone/  →  list of all zones
  /// site-visit/add  →  mark attendance / site visit for a distributor
  static const String kAddSiteVisit = "site-visit/add";

  static const String kGetAllZones = "zone/";

  /// town/zone/{zoneId}  →  towns belonging to a specific zone
  static const String kGetTownsByZone = "town/zone/";

  /// order/tsm/{tsmId}/drafts  →  drafts for a TSM
  static const String kGetDrafts = "order/tsm/";

  /// order/delete/{orderId}  →  permanently delete a draft
  static const String kDeleteOrder = "order/delete/";

  /// product/by-brand/{brandId}/category/{categoryId}
  static const String kGetProductsByBrandAndCategory = "product/by-brand/";

  // ── Warehouse Manager → OrderBooker activity ──────────────────────────────
  // Both are scoped by tsmId (the logged-in warehouseManager's own id) +
  // orderBookerId (the tapped OrderBooker's id).

  /// warehouse-manager/tsm/{tsmId}/order-booker/{orderBookerId}/market-booking-orders
  static String kMarketBookingOrders(String tsmId, String orderBookerId) =>
      "warehouse-manager/tsm/$tsmId/order-booker/$orderBookerId/market-booking-orders";

  /// payment/tsm/{tsmId}/order-booker/{orderBookerId}/market-recovery
  static String kMarketRecoveries(String tsmId, String orderBookerId) =>
      "payment/tsm/$tsmId/order-booker/$orderBookerId/market-recovery";

  /// payment/tsm/{tsmId}/market-recovery?orderBookerId=<optional>&page=<n>&limit=<n>
  ///
  /// Recoveries across ALL order bookers under this TSM by default; pass
  /// [orderBookerId] to filter to just one. Paginated via `page`/`limit`.
  static String kAllMarketRecoveries({
    required String tsmId,
    String? orderBookerId,
    required int page,
    required int limit,
  }) {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (orderBookerId != null && orderBookerId.isNotEmpty)
        'orderBookerId': orderBookerId,
    };
    final query =
    params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return "payment/tsm/$tsmId/market-recovery?$query";
  }

  /// warehouse-manager/{tsmId}/order-bookers
  static String kWarehouseManagerOrderBookers(String tsmId) =>
      "warehouse-manager/$tsmId/order-bookers";

  /// warehouse-manager/order-booker-report?tsmId={tsmId}&orderBookerId={orderBookerId}&type={attendance|tracking|visit|productivity}
  static String kOrderBookerReport({
    required String tsmId,
    required String orderBookerId,
    required String type,
  }) {
    final params = {
      'tsmId': tsmId,
      'orderBookerId': orderBookerId,
      'type': type,
    };
    final query = params.entries
        .map((entry) =>
            '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    return "warehouse-manager/order-booker-report?$query";
  }
}