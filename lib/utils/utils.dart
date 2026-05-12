import 'package:sm_networking/models/bulk_order.dart';
import 'package:sm_networking/models/category.dart';

class Utils {
  static List<CategoryModel> categoryList = [
    CategoryModel("assets/images/wheat.png", "Wheat"),
    CategoryModel("assets/images/oats.png", "Oats"),
    CategoryModel("assets/images/rice.png", "Rice"),
    CategoryModel("assets/images/barly.png", "Barley"),
    CategoryModel("assets/images/corn.png", "Corn"),
    CategoryModel("assets/images/wheat.png", "Wheat"),
    CategoryModel("assets/images/oats.png", "Oats"),
    CategoryModel("assets/images/rice.png", "Rice"),
    CategoryModel("assets/images/corn.png", "Corn"),
  ];
  static List<CategoryModel> brandsList = [
    CategoryModel("assets/images/brand_one.png", "Brand"),
    CategoryModel("assets/images/brand_two.png", "Brand"),
    CategoryModel("assets/images/brand_three.png", "Brand"),
    CategoryModel("assets/images/brand_four.png", "Brand"),
    CategoryModel("assets/images/neon.png", "Neon"),
    CategoryModel("assets/images/brand_three.png", "Brand"),
    CategoryModel("assets/images/brand_four.png", "Brand"),
  ];
  static List<String> sizeList = [
    "1 kg",
    "4 kg",
    "6 kg",
    "8 kg",
    "12 kg",
    "16 kg",
  ];
  static List<BulkOrderModel> bulkOrderList=[
    BulkOrderModel("1 Item", "1200 Rs"),
    BulkOrderModel("10 Item", "1500 Rs"),
    BulkOrderModel("14 Item", "1000 Rs"),
  ];
}
