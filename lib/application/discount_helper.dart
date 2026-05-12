import 'dart:developer';

num getDiscountPrice({required num regularPrice, required num discount}) {
  return regularPrice - ((discount / 100) * regularPrice);
}
