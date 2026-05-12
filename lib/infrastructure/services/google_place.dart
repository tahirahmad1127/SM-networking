import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:http/http.dart' as http;


import '../../presentation/elements/my_logger.dart';
import '../model/place.dart';
import '../model/rooute_info.dart';



class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _distanceMatrixUrl = 'https://maps.googleapis.com/maps/api/distancematrix';
  static const String _geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode';
  static const String _directionsUrl = 'https://maps.googleapis.com/maps/api/directions';
  static const String _apiKey = 'AIzaSyBKYZFNYIWilqG9XT-Y4ei0mPIpkLvO9W8';


  /// Get Place Predictions
  static Future<List<PlacePrediction>> getPlacePredictions(String input) async {
    if (input.isEmpty) {
      AppLogger.debug("❌ getPlacePredictions called with empty input");
      return [];
    }

    final String url = '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&components=country:pk&types=geocode|establishment';

    AppLogger.debug("🌍 Google Places API Request: $url");

    try {
      final response = await http.get(Uri.parse(url));

      AppLogger.debug("📡 Response Status: ${response.statusCode}");
      AppLogger.debug("📦 Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        AppLogger.debug("🔍 Parsed JSON status: ${data['status']}");

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          AppLogger.debug("✅ Predictions count: ${predictions.length}");

          List<PlacePrediction> predictionsList = [];
          for (var prediction in predictions) {
            final placeId = prediction['place_id'];
            AppLogger.debug("➡️ Fetching coordinates for placeId: $placeId");

            final coordinates = await _getCoordinatesFromPlaceId(placeId);

            predictionsList.add(
              PlacePrediction.fromJson(prediction, coordinates),
            );
          }

          return predictionsList;
        } else {
          AppLogger.debug("❌ Google API returned status: ${data['status']}");
          if (data['error_message'] != null) {
            AppLogger.debug("⚠️ Google API error: ${data['error_message']}");
          }
        }
      } else {
        AppLogger.debug("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      AppLogger.debug('❌ Exception in getPlacePredictions: $e');
      AppLogger.debug('StackTrace: $st');
    }

    return [];
  }


  /// Get Coordinates from place id
  static Future<LatLng?> _getCoordinatesFromPlaceId(String placeId) async {
    final String url = '$_baseUrl/details/json?place_id=$placeId&fields=geometry&key=$_apiKey';

    AppLogger.debug("📍 Fetching details for placeId: $placeId");
    AppLogger.debug("🌍 Details Request URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      AppLogger.debug("📡 Details Response Status: ${response.statusCode}");
      AppLogger.debug("📦 Details Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          AppLogger.debug("✅ Coordinates fetched: ${location['lat']}, ${location['lng']}");
          return LatLng(location['lat'], location['lng']);
        } else {
          AppLogger.debug("❌ Places details status: ${data['status']}");
        }
      }
    } catch (e) {
      AppLogger.debug('❌ Error fetching coordinates: $e');
    }

    return null;
  }


  /// Calculate distance and duration between two locations
  static Future<RouteInfo?> getDistanceAndDuration(String origin, String destination) async {
    if (origin.isEmpty || destination.isEmpty) return null;

    final String url =
        '$_distanceMatrixUrl/json?origins=${Uri.encodeComponent(origin)}&destinations=${Uri.encodeComponent(destination)}&key=$_apiKey&units=metric&mode=driving&traffic_model=best_guess&departure_time=now';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['rows'].isNotEmpty) {
          return RouteInfo.fromJson(data['rows'][0]);
        }
      }
    } catch (e) {
      print('Error fetching distance and duration: $e');
    }

    return null;
  }

  /// Get address from coordinates using reverse geocoding
  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    final String url = '$_geocodingUrl/json?latlng=$latitude,$longitude&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error fetching address from coordinates: $e');
    }

    return null;
  }

  /// Calculate travel distance between two coordinates
  static Future<String?> getTravelDistance({required double fromLat, required double fromLng, required double toLat, required double toLng,}) async {
    final String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$fromLat,$fromLng&destinations=$toLat,$toLng&key=$_apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("Distance Matrix Response (Distance): ${jsonEncode(data)}");

        if (data['status'] == 'OK') {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            return element['distance']['text']; // ✅ Distance instead of duration
          } else {
            debugPrint("Element status: ${element['status']}");
          }
        } else {
          debugPrint("Response status not OK: ${data['status']}");
        }
      }
    } catch (e) {
      print('Error fetching travel distance: $e');
    }

    return null;
  }


  /// Get duration from lat long from and to coordinates
  static Future<String?> getTravelDuration({required double fromLat, required double fromLng, required double toLat, required double toLng,}) async {
    final String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$fromLat,$fromLng&destinations=$toLat,$toLng&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("Distance Matrix Response: ${jsonEncode(data)}");

        if (data['status'] == 'OK') {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            return element['duration']['text'];
          } else {
            debugPrint("Element status: ${element['status']}");
          }
        } else {
          debugPrint("Response status not OK: ${data['status']}");
        }
      }

    } catch (e) {
      print('Error fetching travel duration: $e');
    }

    return null;
  }

  /// Get travel distance & duration between two coordinates
  static Future<RouteInfo?> getRouteInfo({required double fromLat, required double fromLng, required double toLat, required double toLng,}) async {
    final String url = 'https://maps.googleapis.com/maps/api/distancematrix/json''?origins=$fromLat,$fromLng''&destinations=$toLat,$toLng''&key=$_apiKey''&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("📦 Distance Matrix Response: ${jsonEncode(data)}");

        if (data['status'] == 'OK') {
          final row = data['rows'][0];
          return RouteInfo.fromJson(row);
        } else {
          debugPrint("Response status not OK: ${data['status']}");
        }
      } else {
        debugPrint("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Error fetching route info: $e');
    }

    return null;
  }

  /// Get polyline points for directions
  static Future<List<LatLng>> getDirectionsPolyline(
      LatLng origin, LatLng destination) async {
    final String url =
        '$_directionsUrl/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey&mode=driving';

    try {
      final response = await http.get(Uri.parse(url));
      log('Fetching directions from: $url');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final polylineString =
              data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(polylineString);
        }
      }
    } catch (e) {
      print('Error fetching directions: $e');
    }

    return [];
  }

  /// Decode polyline string to list of LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylinePoints = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylinePoints;
  }
}
