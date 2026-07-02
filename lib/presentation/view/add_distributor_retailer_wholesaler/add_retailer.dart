import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:place_picker/entities/location_result.dart';
import 'package:place_picker/widgets/place_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sm_networking/application/locaition_helper.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/back_end_configs.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';

import '../../../infrastructure/model/user.dart';
import 'add_distributor.dart'; // re-use ZoneModel / TownModel

class AddRetailerView extends StatefulWidget {
  const AddRetailerView({super.key});

  @override
  State<AddRetailerView> createState() => _AddRetailerViewState();
}

class _AddRetailerViewState extends State<AddRetailerView> {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _marketNameController = TextEditingController();
  final _bazarNameController = TextEditingController();
  final _roadNameController = TextEditingController();
  final _streetNameController = TextEditingController();

  // ── Image ────────────────────────────────────────────────────────────────
  File? _profileImage;

  // ── Map ──────────────────────────────────────────────────────────────────
  Set<Marker> _markers = {};
  LatLng? _currentLocation;
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _mapCompleter = Completer();
  double _lat = 0.0;
  double _lng = 0.0;
  bool _locationSet = false;

  // ── Zone / Town ───────────────────────────────────────────────────────────
  List<ZoneModel> _zones = [];
  List<TownModel> _filteredTowns = [];
  ZoneModel? _selectedZone;
  TownModel? _selectedTown;
  bool _loadingZones = false;
  bool _loadingTowns = false;

  // ── Role-based locks ─────────────────────────────────────────────────────
  String _role = '';
  String? _lockedZoneId;
  String? _lockedZoneName;
  String? _lockedTownId;
  String? _lockedTownName;

  bool get _zoneIsLocked =>
      _role == 'warehouseManager' || _role == 'orderBooker';
  bool get _townIsLocked => _role == 'orderBooker';

  // ── Submit ────────────────────────────────────────────────────────────────
  bool _isLoading = false;

  // ── Inline field errors ───────────────────────────────────────────────────
  String? _nameError;
  String? _phoneError;

  final ApiBaseHelper _api = ApiBaseHelper();

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initLocation();
    _initRoleAndLocks();
  }

  void _initRoleAndLocks() {
    final userModel =
    Provider.of<UserProvider>(context, listen: false).getSalesUserDetails();
    _role = userModel?.role ?? '';
    final user = userModel?.user;

    if (_role == 'warehouseManager' || _role == 'orderBooker') {
      _lockedZoneId = user?.zone;
      if (_role == 'orderBooker' && (user?.town?.isNotEmpty ?? false)) {
        _lockedTownId = user!.town!.first;
      }
    }
    _fetchZones();
  }

  // ── Location ───────────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      final pos = await determinePosition();
      final latLng = LatLng(pos.latitude!, pos.longitude!);
      _currentLocation = latLng;
      _lat = pos.latitude;
      _lng = pos.longitude;
      _markers.add(Marker(markerId: const MarkerId('current'), position: latLng));
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _showPlacePicker() async {
    final LocationResult result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlacePicker(
          "AIzaSyAuJYLmzmglhCpBYTn0BjbJhjWYg0fPEEA",
          displayLocation: _currentLocation,
        ),
      ),
    );
    if (result.latLng == null) return;
    _lat = result.latLng!.latitude;
    _lng = result.latLng!.longitude;
    _locationSet = true;

    final address = (result.formattedAddress != null &&
        result.formattedAddress!.trim().isNotEmpty)
        ? result.formattedAddress!
        : (result.name != null && result.name!.trim().isNotEmpty)
        ? result.name!
        : '${_lat.toStringAsFixed(6)}, ${_lng.toStringAsFixed(6)}';
    _addressController.text = address;

    _markers
      ..clear()
      ..add(Marker(
          markerId: const MarkerId('picked'), position: LatLng(_lat, _lng)));
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(_lat, _lng), zoom: 16)));
    setState(() {});
  }

  // ── API Calls ─────────────────────────────────────────────────────────────
  Future<void> _fetchZones() async {
    setState(() => _loadingZones = true);
    try {
      final token = Provider.of<UserProvider>(context, listen: false)
          .getSalesUserDetails()
          ?.token ??
          '';
      final result = await _api.getEither(
        endPoint: 'zone/',
        isRequiredHeader: true,
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      result.fold(
            (error) =>
            getFlushBar(context, title: error.error ?? 'Failed to load zones'),
            (data) {
          final list = (data['data'] as List)
              .map((e) => ZoneModel.fromJson(e))
              .toList();
          if (!mounted) return;
          setState(() => _zones = list);

          if (_zoneIsLocked && _lockedZoneId != null) {
            final match = list.where((z) => z.id == _lockedZoneId).firstOrNull;
            if (match != null) {
              setState(() {
                _selectedZone = match;
                _lockedZoneName = match.name;
              });
              _fetchTownsByZone(match.id);
            }
          }
        },
      );
    } catch (e) {
      if (mounted) getFlushBar(context, title: 'Error loading zones: $e');
    } finally {
      if (mounted) setState(() => _loadingZones = false);
    }
  }

  Future<void> _fetchTownsByZone(String zoneId) async {
    setState(() {
      _loadingTowns = true;
      _filteredTowns = [];
      _selectedTown = null;
    });
    try {
      final token = Provider.of<UserProvider>(context, listen: false)
          .getSalesUserDetails()
          ?.token ??
          '';
      final result = await _api.getEither(
        endPoint: 'town/zone/$zoneId',
        isRequiredHeader: true,
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      result.fold(
            (error) =>
            getFlushBar(context, title: error.error ?? 'Failed to load towns'),
            (data) {
          final list = (data['data'] as List)
              .map((e) => TownModel.fromJson(e))
              .toList();
          if (!mounted) return;
          setState(() => _filteredTowns = list);

          if (_townIsLocked && _lockedTownId != null) {
            final match =
                list.where((t) => t.id == _lockedTownId).firstOrNull;
            if (match != null) {
              setState(() {
                _selectedTown = match;
                _lockedTownName = match.name;
              });
            }
          }
        },
      );
    } catch (e) {
      if (mounted) getFlushBar(context, title: 'Error loading towns: $e');
    } finally {
      if (mounted) setState(() => _loadingTowns = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    bool hasError = false;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameError = "Fill please";
      hasError = true;
    } else {
      _nameError = null;
    }

    final phoneRaw = _phoneController.text.trim();
    if (phoneRaw.isNotEmpty) {
      final bool startsWithPlus923 = phoneRaw.startsWith('+923');
      final bool startsWith03 = phoneRaw.startsWith('03');
      if (!startsWithPlus923 && !startsWith03) {
        _phoneError = "Please write a valid phone number";
        hasError = true;
      } else if (startsWithPlus923 && phoneRaw.length != 13) {
        _phoneError = "Phone number must be 13 characters for +923 format";
        hasError = true;
      } else if (startsWith03 && phoneRaw.length != 11) {
        _phoneError = "Phone number must be 11 characters";
        hasError = true;
      } else {
        _phoneError = null;
      }
    } else {
      _phoneError = null;
    }

    setState(() {});
    if (hasError) return;

    if (_selectedZone == null) {
      getFlushBar(
          context,
          title: _zoneIsLocked
              ? "Zone could not be loaded. Please try again."
              : "Please select a zone.");
      return;
    }
    if (_selectedTown == null) {
      getFlushBar(
          context,
          title: _townIsLocked
              ? "Town could not be loaded. Please try again."
              : "Please select a town.");
      return;
    }
    if (!_locationSet) {
      getFlushBar(context,
          title: "Please set the shop location before submitting.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<UserProvider>(context, listen: false)
          .getSalesUserDetails()
          ?.token ??
          '';
      final authHeader = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final body = <String, dynamic>{
        'name': name,
        if (phoneRaw.isNotEmpty) 'contacts': phoneRaw,
        'zone': _selectedZone!.id,
        'town': _selectedTown!.id,
        if (_addressController.text.trim().isNotEmpty)
          'address': _addressController.text.trim(),
        'marketName': _marketNameController.text.trim(),
        'bazarName': _bazarNameController.text.trim(),
        'roadName': _roadNameController.text.trim(),
        'streetName': _streetNameController.text.trim(),
        'addressFromGoogle': {
          'lat': _lat,
          'lng': _lng,
        },
      };

      String? newId;

      if (_profileImage != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${BackendConfigs.apiUrl}retailer/add'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        body.forEach((key, value) {
          if (value is Map) {
            // send nested map as JSON string or skip — backend handles addressFromGoogle separately
            request.fields[key] = jsonEncode(value);
          } else if (value != null) {
            request.fields[key] = value.toString();
          }
        });
        request.files.add(await http.MultipartFile.fromPath(
          'pic',
          _profileImage!.path,
        ));

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        final responseBody = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          newId = responseBody['data']?['_id'] as String?;
        } else {
          if (mounted) {
            final msg = responseBody['msg'] ??
                responseBody['message'] ??
                responseBody['error'] ??
                'Failed to add retailer (${response.statusCode}).';
            getFlushBar(context, title: msg.toString());
          }
          return;
        }
      } else {
        final result = await _api.postEither(
          endPoint: 'retailer/add',
          isRequiredHeader: true,
          hasBody: true,
          body: body,
          header: authHeader,
        );

        bool failed = false;
        result.fold(
              (error) {
            failed = true;
            if (mounted)
              getFlushBar(context, title: error.error ?? 'Something went wrong.');
          },
              (data) {
            newId = data['data']?['_id'] as String?;
          },
        );
        if (failed) return;
      }

      if (mounted && newId != null) {
        final newRetailer = Wholesaler(
          id: newId,
          name: name,
          contacts: phoneRaw.isNotEmpty ? phoneRaw : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          zone: DistributorRef(
            id: _selectedZone!.id,
            name: _selectedZone!.name,
          ),
          town: DistributorRef(
            id: _selectedTown!.id,
            name: _selectedTown!.name,
          ),
          isActive: true,
          isAdminVerified: false,
          isDeleted: false,
          addressFromGoogle: DistributorLocation(lat: _lat, lng: _lng),
        );

        final userProvider =
        Provider.of<UserProvider>(context, listen: false);
        final currentList = List<Wholesaler>.from(
          userProvider.getSalesUserDetails()?.retailers ?? [],
        );
        currentList.add(newRetailer);
        userProvider.updateRetailers(currentList);

        // Persist updated model to SharedPreferences so it survives restart
        final prefs = await SharedPreferences.getInstance();
        final updatedModel = userProvider.getSalesUserDetails();
        if (updatedModel != null) {
          await prefs.setString('USER_DATA', userModelToJson(updatedModel));
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) getFlushBar(context, title: 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: 'Add Retailer', showText: true),
      body: _currentLocation == null
          ? const Center(child: ProcessingWidget())
          : LoadingOverlay(
        isLoading: _isLoading,
        progressIndicator: const ProcessingWidget(),
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Image ──────────────────────────────────────
              _label("Profile Image (Optional)"),
              _buildImagePicker(
                image: _profileImage,
                title: "Upload Profile Image",
                onImageChanged: (file) =>
                    setState(() => _profileImage = file),
                onCrop: () => _cropImage(),
                onEdit: () => _editImage(),
                onRemove: () => setState(() => _profileImage = null),
              ),
              _sectionGap(),

              // ── Name ──────────────────────────────────────────────
              _label("Name"),
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                onChanged: (_) {
                  if (_nameError != null)
                    setState(() => _nameError = null);
                },
                decoration: _fieldDecoration("Name").copyWith(
                  errorText: _nameError,
                  errorMaxLines: 2,
                ),
              ),
              _sectionGap(),

              // ── Phone Number ───────────────────────────────────────
              _label("Phone Number (Optional)"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(13),
                ],
                onChanged: (_) {
                  if (_phoneError != null)
                    setState(() => _phoneError = null);
                },
                decoration: _fieldDecoration("Phone Number").copyWith(
                  errorText: _phoneError,
                  errorMaxLines: 2,
                ),
              ),
              _sectionGap(),

              // ── Zone ───────────────────────────────────────────────
              _label("Zone", locked: _zoneIsLocked),
              _zoneIsLocked
                  ? _buildReadOnlyField(
                _lockedZoneName ??
                    (_loadingZones ? "Loading..." : "—"),
                locked: true,
              )
                  : _buildDropdown<ZoneModel>(
                hint: _loadingZones
                    ? "Loading zones..."
                    : "Select Zone",
                value: _selectedZone,
                items: _zones
                    .map((z) => DropdownMenuItem<ZoneModel>(
                  value: z,
                  child: Text(z.name),
                ))
                    .toList(),
                onChanged: (zone) {
                  setState(() {
                    _selectedZone = zone;
                    _selectedTown = null;
                    _filteredTowns = [];
                  });
                  if (zone != null) _fetchTownsByZone(zone.id);
                },
              ),
              _sectionGap(),

              // ── Town ───────────────────────────────────────────────
              _label("Town"),
              _townIsLocked
                  ? _buildReadOnlyField(
                _lockedTownName ??
                    (_loadingTowns ? "Loading..." : "—"),
                locked: true,
              )
                  : _buildDropdown<TownModel>(
                hint: _loadingTowns
                    ? "Loading towns..."
                    : (_selectedZone == null
                    ? "Select Zone first"
                    : "Select Town"),
                value: _selectedTown,
                items: _filteredTowns
                    .map((t) => DropdownMenuItem<TownModel>(
                  value: t,
                  child: Text(t.name),
                ))
                    .toList(),
                onChanged: _selectedZone == null
                    ? null
                    : (town) =>
                    setState(() => _selectedTown = town),
              ),
              _sectionGap(),

              // ── Map Location ───────────────────────────────────────
              _label("Map Location (Address From Google)"),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FrontendConfigs.kTextFieldColor,
                  borderRadius: FrontendConfigs.kAppBorder,
                ),
                child: Row(
                  children: [
                    Icon(
                      _locationSet
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _locationSet ? Colors.green : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationSet
                            ? "Location set: ${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}"
                            : "No Location Set",
                        style: TextStyle(
                          color: FrontendConfigs.kAuthTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_locationSet) ...[
                const SizedBox(height: 8),
                Text(
                  "Click 'Set Location' to pin the location on the map",
                  style: TextStyle(
                    fontSize: 12,
                    color: FrontendConfigs.kAuthTextColor,
                  ),
                ),
              ],
              const SizedBox(height: 8),

              if (_locationSet) ...[
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: FrontendConfigs.kAppBorder,
                    child: GoogleMap(
                      zoomControlsEnabled: false,
                      markers: _markers,
                      onTap: (_) => _showPlacePicker(),
                      mapType: MapType.normal,
                      mapToolbarEnabled: false,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_lat, _lng),
                        zoom: 16,
                      ),
                      onMapCreated:
                          (GoogleMapController ctrl) async {
                        if (!_mapCompleter.isCompleted) {
                          _mapCompleter.complete(ctrl);
                        }
                        _mapController = await _mapCompleter.future;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showPlacePicker,
                  icon: const Icon(Icons.location_on),
                  label: Text(
                      _locationSet ? "Change Location" : "Set Location"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FrontendConfigs.kPrimaryColor,
                    side:
                    BorderSide(color: FrontendConfigs.kPrimaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: FrontendConfigs.kAppBorder,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Market Name ────────────────────────────────────────
              _label("Market Name"),
              TextFormField(
                controller: _marketNameController,
                decoration: InputDecoration(
                  hintText: "Enter market name",
                  hintStyle: TextStyle(
                    color: FrontendConfigs.kAuthTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: FrontendConfigs.kAppBorder,
                    borderSide: BorderSide.none,
                  ),
                  fillColor: FrontendConfigs.kTextFieldColor,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              _sectionGap(),

              // ── Bazar Name ─────────────────────────────────────────
              _label("Bazar Name"),
              TextFormField(
                controller: _bazarNameController,
                decoration: InputDecoration(
                  hintText: "Enter bazar name",
                  hintStyle: TextStyle(
                    color: FrontendConfigs.kAuthTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: FrontendConfigs.kAppBorder,
                    borderSide: BorderSide.none,
                  ),
                  fillColor: FrontendConfigs.kTextFieldColor,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              _sectionGap(),

              // ── Road Name ──────────────────────────────────────────
              _label("Road Name"),
              TextFormField(
                controller: _roadNameController,
                decoration: InputDecoration(
                  hintText: "Enter road name",
                  hintStyle: TextStyle(
                    color: FrontendConfigs.kAuthTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: FrontendConfigs.kAppBorder,
                    borderSide: BorderSide.none,
                  ),
                  fillColor: FrontendConfigs.kTextFieldColor,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              _sectionGap(),

              // ── Street Name ────────────────────────────────────────
              _label("Street Name"),
              TextFormField(
                controller: _streetNameController,
                decoration: InputDecoration(
                  hintText: "Enter street name",
                  hintStyle: TextStyle(
                    color: FrontendConfigs.kAuthTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: FrontendConfigs.kAppBorder,
                    borderSide: BorderSide.none,
                  ),
                  fillColor: FrontendConfigs.kTextFieldColor,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              _sectionGap(),

              // ── Submit ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FrontendConfigs.kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: FrontendConfigs.kAppBorder,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Add Retailer",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text, {bool locked = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (locked) ...[
          const SizedBox(width: 6),
          Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
        ],
      ],
    ),
  );

  Widget _sectionGap() => const SizedBox(height: 16);

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: FrontendConfigs.kAuthTextColor,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    border: OutlineInputBorder(
      borderRadius: FrontendConfigs.kAppBorder,
      borderSide: BorderSide.none,
    ),
    fillColor: FrontendConfigs.kTextFieldColor,
    filled: true,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  Widget _buildReadOnlyField(String text, {bool locked = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: locked
          ? FrontendConfigs.kTextFieldColor.withValues(alpha: 0.7)
          : FrontendConfigs.kTextFieldColor,
      borderRadius: FrontendConfigs.kAppBorder,
      border: locked
          ? Border.all(color: Colors.grey.shade300, width: 1)
          : null,
    ),
    child: Text(
      text,
      style: TextStyle(
        color: locked ? Colors.grey.shade600 : Colors.black87,
        fontSize: 14,
      ),
    ),
  );

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: FrontendConfigs.kTextFieldColor,
          borderRadius: FrontendConfigs.kAppBorder,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            hint: Text(
              hint,
              style: TextStyle(
                color: FrontendConfigs.kAuthTextColor,
                fontSize: 14,
              ),
            ),
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      );

  // ── Image Picker Widget ───────────────────────────────────────────────────
  Widget _buildImagePicker({
    required File? image,
    required String title,
    required ValueChanged<File> onImageChanged,
    required VoidCallback onCrop,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: () => _showImagePickerBottomSheet(
        context,
        title: title,
        onImageChanged: onImageChanged,
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: FrontendConfigs.kTextFieldColor,
              borderRadius: FrontendConfigs.kAppBorder,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: image != null
                ? ClipRRect(
              borderRadius: FrontendConfigs.kAppBorder,
              child: Image.file(image, fit: BoxFit.cover),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FrontendConfigs.kPrimaryColor
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.doc_on_clipboard,
                    color: FrontendConfigs.kPrimaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Click to upload or drag and drop",
                  style: TextStyle(
                    color: FrontendConfigs.kPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "JPG, PNG etc (max. 10MB)",
                  style: TextStyle(
                    color: FrontendConfigs.kAuthTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (image != null)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _imageActionButton(
                    icon: Icons.crop,
                    tooltip: 'Crop',
                    onTap: onCrop,
                  ),
                  const SizedBox(width: 6),
                  _imageActionButton(
                    icon: Icons.tune,
                    tooltip: 'Edit',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 6),
                  _imageActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Remove',
                    onTap: onRemove,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  void _showImagePickerBottomSheet(
      BuildContext context, {
        required String title,
        required ValueChanged<File> onImageChanged,
      }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            CustomText(
              text: title,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                  FrontendConfigs.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.camera,
                    color: FrontendConfigs.kPrimaryColor),
              ),
              title: const Text('Camera',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndEdit(
                    source: ImageSource.camera,
                    onImageChanged: onImageChanged);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                  FrontendConfigs.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.photo,
                    color: FrontendConfigs.kPrimaryColor),
              ),
              title: const Text('Gallery',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndEdit(
                    source: ImageSource.gallery,
                    onImageChanged: onImageChanged);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndEdit({
    required ImageSource source,
    required ValueChanged<File> onImageChanged,
  }) async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(imageQuality: 60, source: source);
    if (pickedFile == null) return;
    final bytes = await File(pickedFile.path).readAsBytes();
    await _openProEditor(bytes, onImageChanged: onImageChanged);
  }

  Future<void> _cropImage() async {
    if (_profileImage == null) return;
    final bytes = await _profileImage!.readAsBytes();
    await _openProEditor(
      bytes,
      onImageChanged: (file) => setState(() => _profileImage = file),
    );
  }

  Future<void> _editImage() async {
    if (_profileImage == null) return;
    final bytes = await _profileImage!.readAsBytes();
    await _openProEditor(
      bytes,
      onImageChanged: (file) => setState(() => _profileImage = file),
    );
  }

  Future<void> _openProEditor(
      Uint8List bytes, {
        required ValueChanged<File> onImageChanged,
      }) async {
    Uint8List? result;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProImageEditor.memory(
          bytes,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List edited) async {
              result = edited;
              Navigator.pop(context);
            },
          ),
          configs: const ProImageEditorConfigs(),
        ),
      ),
    );

    if (result != null) {
      final dir = Directory.systemTemp;
      final path =
          '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressWithList(
        result!,
        quality: 50,
        format: CompressFormat.jpeg,
      );
      final saved = await File(path).writeAsBytes(compressed);
      onImageChanged(saved);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _marketNameController.dispose();
    _bazarNameController.dispose();
    _roadNameController.dispose();
    _streetNameController.dispose();
    super.dispose();
  }
}