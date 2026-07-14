import 'package:get_it/get_it.dart';
import 'package:sm_networking/application/attendance_bloc/attendance_bloc.dart';
import 'package:sm_networking/application/brand_bloc/brand_bloc.dart';
import 'package:sm_networking/application/category_bloc/category_bloc.dart';
import 'package:sm_networking/application/coupon_bloc/coupon_bloc.dart';
import 'package:sm_networking/application/order_bloc/order_bloc.dart';
import 'package:sm_networking/application/retailer_bloc/retailer_bloc.dart';
import 'package:sm_networking/application/setting_bloc/setting_bloc.dart';
import 'package:sm_networking/application/stats_bloc/stats_bloc.dart';
import 'package:sm_networking/application/tracking_bloc/tracking_bloc.dart';
import 'package:sm_networking/application/visit_bloc/visit_bloc.dart';
import 'package:sm_networking/infrastructure/services/attendance.dart';
import 'package:sm_networking/infrastructure/services/coupon.dart';
import 'package:sm_networking/infrastructure/services/stats.dart';
import 'package:sm_networking/infrastructure/services/order.dart';
import 'package:sm_networking/infrastructure/services/Setting.dart';
import 'package:sm_networking/infrastructure/services/product.dart';
import 'package:sm_networking/infrastructure/services/brand.dart';
import 'package:sm_networking/infrastructure/services/Category.dart';
import 'package:sm_networking/infrastructure/services/retailer.dart';
import 'package:sm_networking/infrastructure/services/tracking.dart';
import 'package:sm_networking/infrastructure/services/visit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/auth_bloc/login_bloc.dart';
import 'application/product_bloc/product_bloc.dart';
import 'infrastructure/services/auth.dart';
import 'infrastructure/services/brand_category.dart';

final sl = GetIt.instance;

Future<void> init() async {
  ///Blocs

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
  sl.registerFactory<RetailerBloc>(() => RetailerBloc(sl()));
  sl.registerFactory<CategoryBloc>(() => CategoryBloc(sl()));
  sl.registerFactory<BrandBloc>(() => BrandBloc(sl()));
  sl.registerFactory<ProductBloc>(() => ProductBloc(sl()));
  sl.registerFactory<SettingBloc>(() => SettingBloc(sl()));
  sl.registerFactory<OrderBloc>(() => OrderBloc(sl()));
  sl.registerFactory<StatsBloc>(() => StatsBloc(sl()));
  sl.registerFactory<AttendanceBloc>(() => AttendanceBloc(sl()));
  sl.registerFactory<VisitBloc>(() => VisitBloc(sl()));
  sl.registerFactory<CouponBloc>(() => CouponBloc(sl()));
  sl.registerFactory<TrackingBloc>(() => TrackingBloc(sl()));

  ///Services

  sl.registerLazySingleton(() => AuthRepositoryImp());
  sl.registerLazySingleton<RetailerRepositoryImp>(
      () => RetailerRepositoryImp());
  sl.registerLazySingleton(() => CategoryRepositoryImp());
  sl.registerLazySingleton(() => BrandRepositoryImp());
  sl.registerLazySingleton(() => BrandCategoryService());
  sl.registerLazySingleton(() => ProductRepositoryImp());
  sl.registerLazySingleton(() => SettingRepositoryImp());
  sl.registerLazySingleton(() => OrderRepositoryImp());
  sl.registerLazySingleton(() => StatsRepositoryImp());
  sl.registerLazySingleton(() => AttendanceRepositoryImp());
  sl.registerLazySingleton(() => VisitRepositoryImp());
  sl.registerLazySingleton(() => CouponRepositoryImp());
  sl.registerLazySingleton(() => TrackingRepositoryImp());

  ///Utils
  sl.registerSingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance());
}
