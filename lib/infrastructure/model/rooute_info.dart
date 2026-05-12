class RouteInfo {
  final String distance;
  final String duration;
  final String distanceValue; // in meters
  final String durationValue; // in seconds

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    final element = json['elements'][0];

    if (element['status'] == 'OK') {
      return RouteInfo(
        distance: element['distance']['text'] ?? '',
        duration: element['duration']['text'] ?? '',
        distanceValue: element['distance']['value'].toString(),
        durationValue: element['duration']['value'].toString(),
      );
    }

    return RouteInfo(
      distance: 'N/A',
      duration: 'N/A',
      distanceValue: '0',
      durationValue: '0',
    );
  }
}