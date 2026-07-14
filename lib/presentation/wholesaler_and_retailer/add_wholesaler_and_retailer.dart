import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:place_picker/entities/location_result.dart';
import 'package:place_picker/widgets/place_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/locaition_helper.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/application/wholesaler_retailer_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/infrastructure/model/wholesaler_retailer_model.dart';
import 'package:sm_networking/infrastructure/services/wholesaler_retailer_service.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/wholesaler_and_retailer/wholesailer_and_retailer.dart';

// ── Shared Zone / Town models (local copies — extract to shared file when ready)

class _ZoneModel {
  final String id;
  final String name;
  final String locationId;

  _ZoneModel({required this.id, required this.name, required this.locationId});

  factory _ZoneModel.fromJson(Map<String, dynamic> json) => _ZoneModel(
    id: json['_id'] ?? '',
    name: json['name'] ?? '',
    locationId: json['locationId'] ?? '',
  );
}

class _TownModel {
  final String id;
  final String name;
  final String locationId;
  final String zoneId;

  _TownModel(
      {required this.id,
        required this.name,
        required this.locationId,
        required this.zoneId});

  factory _TownModel.fromJson(Map<String, dynamic> json) => _TownModel(
    id: json['_id'] ?? '',
    name: json['name'] ?? '',
    locationId: json['locationId'] ?? '',
    zoneId: (json['zoneId'] is Map)
        ? (json['zoneId']['_id'] ?? '')
        : (json['zoneId'] ?? ''),
  );
}

// ─── View ─────────────────────────────────────────────────────────────────────

class AddWholesalerRetailerView extends StatefulWidget {
  final WholesalerRetailerType type;

  const AddWholesalerRetailerView({super.key, required this.type});

  @override
  State<AddWholesalerRetailerView> createState() =>
      _AddWholesalerRetailerViewState();
}

class _AddWholesalerRetailerViewState
    extends State<AddWholesalerRetailerView> {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _marketNameController = TextEditingController();
  final _bazarNameController = TextEditingController();
  final _roadNameController = TextEditingController();
  final _streetNameController = TextEditingController(); // retailer only
  final _shopAddressController = TextEditingController();

  // ── Image ─────────────────────────────────────────────────────────────────
  File? _profileImage;

  // ── Map ───────────────────────────────────────────────────────────────────
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _mapCompleter = Completer();
  double _lat = 0.0;
  double _lng = 0.0;
  bool _locationSet = false;

  // ── Zone / Town ───────────────────────────────────────────────────────────
  List<_ZoneModel> _zones = [];
  List<_TownModel> _filteredTowns = [];
  _ZoneModel? _selectedZone;
  _TownModel? _selectedTown;
  bool _loadingZones = false;
  bool _loadingTowns = false;

  // ── Role-based locks ──────────────────────────────────────────────────────
  String _role = '';
  String? _lockedZoneId;
  String? _lockedZoneName;
  String? _lockedTownId;
  String? _lockedTownName;

  bool get _zoneIsLocked =>
      _role == 'warehouseManager' || _role == 'orderBooker';
  bool get _townIsLocked => _role == 'orderBooker';

  // ── Validation errors ─────────────────────────────────────────────────────
  String? _nameError;
  String? _contactError;

  // ── Other state ───────────────────────────────────────────────────────────
  bool _isLoading = false;

  final ApiBaseHelper _api = ApiBaseHelper();
  final WholesalerRetailerService _service = WholesalerRetailerService();

  String get _typeLabel =>
      widget.type == WholesalerRetailerType.wholesaler
          ? 'Wholesaler'
          : 'Retailer';

  /// API endpoint differs by type — mirrors kAddWholesaler / kAddRetailer
  String get _endpoint =>
      widget.type == WholesalerRetailerType.wholesaler
          ? 'wholesaler/add'
          : 'retailer/add';

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

    if (_zoneIsLocked) {
      _lockedZoneId = user?.zone;
    }
    if (_townIsLocked && (user?.town?.isNotEmpty ?? false)) {
      _lockedTownId = user!.town!.first;
    }
    _fetchZones();
  }

  // ── Location ──────────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      final pos = await determinePosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      _currentLocation = latLng;
      _lat = pos.latitude;
      _lng = pos.longitude;
      _markers
          .add(Marker(markerId: const MarkerId('current'), position: latLng));
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
    _shopAddressController.text = address;

    _markers
      ..clear()
      ..add(Marker(
          markerId: const MarkerId('picked'), position: LatLng(_lat, _lng)));
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(_lat, _lng), zoom: 16)));
    setState(() {});
  }

  // ── API: Zones & Towns (unchanged from original) ──────────────────────────
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
              .map((e) => _ZoneModel.fromJson(e))
              .toList();
          if (!mounted) return;
          setState(() => _zones = list);

          if (_zoneIsLocked && _lockedZoneId != null) {
            final match =
                list.where((z) => z.id == _lockedZoneId).firstOrNull;
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
              .map((e) => _TownModel.fromJson(e))
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

  // ── Validation & Submit ───────────────────────────────────────────────────
  Future<void> _submit() async {
    bool hasError = false;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameError = "Fill please";
      hasError = true;
    } else if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(name)) {
      _nameError = "Name must contain letters only";
      hasError = true;
    } else {
      _nameError = null;
    }

    final phone = _contactController.text.trim();
    if (phone.isEmpty) {
      _contactError = "Fill please";
      hasError = true;
    } else {
      final bool startsWithPlus923 = phone.startsWith('+923');
      final bool startsWith03 = phone.startsWith('03');
      if (!startsWithPlus923 && !startsWith03) {
        _contactError = "Please enter a valid phone number";
        hasError = true;
      } else if (startsWithPlus923 && phone.length != 13) {
        _contactError = "Must be 13 characters for +923 format";
        hasError = true;
      } else if (startsWith03 && phone.length != 11) {
        _contactError = "Must be 11 characters";
        hasError = true;
      } else {
        _contactError = null;
      }
    }

    setState(() {});
    if (hasError) return;

    if (_selectedZone == null) {
      getFlushBar(context,
          title: _zoneIsLocked
              ? "Zone could not be loaded. Please try again."
              : "Please select a zone.");
      return;
    }
    if (_selectedTown == null) {
      getFlushBar(context,
          title: _townIsLocked
              ? "Town could not be loaded. Please try again."
              : "Please select a town.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDetails = Provider.of<UserProvider>(context, listen: false)
          .getSalesUserDetails();
      final token = userDetails?.token ?? '';

      // Build the request model — matches the API shape exactly
      final requestModel = AddWholesalerRetailerModel(
        name: name,
        contacts: phone,
        zone: _selectedZone!.id,
        town: _selectedTown!.id,
        address: _shopAddressController.text.trim(),
        marketName: _marketNameController.text.trim(),
        bazarName: _bazarNameController.text.trim(),
        roadName: _roadNameController.text.trim(),
        streetName: widget.type == WholesalerRetailerType.retailer
            ? _streetNameController.text.trim()
            : null,
        lat: _lat,
        lng: _lng,
      );

      // POST to the correct endpoint (wholesaler/add or retailer/add)
      final created = await _service.addEntry(
        endpoint: _endpoint,
        model: requestModel,
        token: token,
        imageFile: _profileImage,
      );

      if (!mounted) return;

      // ── Optimistic update: prepend to the in-memory provider list ─────────
      // Same technique as AddDistributorView → userProvider.updateDistributors()
      final provider = Provider.of<WholesalerRetailerProvider>(
          context,
          listen: false);

      if (widget.type == WholesalerRetailerType.wholesaler) {
        provider.appendWholesaler(created);
      } else {
        provider.appendRetailer(created);
      }

      // Pop first — calling getFlushBar AND Navigator.pop in the same frame
      // triggers the '!_debugLocked' Navigator assertion because both try to
      // mutate the Navigator in the same build cycle.
      // The success message is shown on the listing screen instead (see below).
      Navigator.pop(context, true);
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
      appBar: customAppBar(context, text: 'Add $_typeLabel', showText: true),
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
              // ── Profile Image ─────────────────────────────────────
              _label("Profile Image (Optional)"),
              _buildImagePicker(
                image: _profileImage,
                title: "Upload Profile Image",
                onImageChanged: (file) =>
                    setState(() => _profileImage = file),
                onCrop: () => _cropOrEditImage(),
                onEdit: () => _cropOrEditImage(),
                onRemove: () => setState(() => _profileImage = null),
              ),
              _sectionGap(),

              // ── Name ──────────────────────────────────────────────
              _label("Name"),
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))
                ],
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
                decoration: _fieldDecoration("Full Name").copyWith(
                  errorText: _nameError,
                  errorMaxLines: 2,
                ),
              ),
              _sectionGap(),

              // ── Contact No ────────────────────────────────────────
              _label("Contact No"),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(13),
                ],
                onChanged: (_) {
                  if (_contactError != null) {
                    setState(() => _contactError = null);
                  }
                },
                decoration:
                _fieldDecoration("e.g. 03001234567").copyWith(
                  errorText: _contactError,
                  errorMaxLines: 2,
                ),
              ),
              _sectionGap(),

              // ── Market Name ─────────────────────────────────────
              _label("Market Name"),
              TextFormField(
                controller: _marketNameController,
                keyboardType: TextInputType.streetAddress,
                decoration: _fieldDecoration("Enter market name"),
              ),
              _sectionGap(),

              // ── Bazar Name ───────────────────────────────────────
              _label("Bazar Name"),
              TextFormField(
                controller: _bazarNameController,
                keyboardType: TextInputType.streetAddress,
                decoration: _fieldDecoration("Enter bazar name"),
              ),
              _sectionGap(),

              // ── Road Name ────────────────────────────────────────
              _label("Road Name"),
              TextFormField(
                controller: _roadNameController,
                keyboardType: TextInputType.streetAddress,
                decoration: _fieldDecoration("Enter road name"),
              ),
              _sectionGap(),

              // ── Street Name (Retailer only) ───────────────────────
              if (widget.type == WholesalerRetailerType.retailer) ...[
                _label("Street Name"),
                TextFormField(
                  controller: _streetNameController,
                  keyboardType: TextInputType.streetAddress,
                  decoration: _fieldDecoration("Enter street name"),
                ),
                _sectionGap(),
              ],

              // ── Zone ─────────────────────────────────────────────
              _label("Zone", locked: _zoneIsLocked),
              _zoneIsLocked
                  ? _buildReadOnlyField(
                _lockedZoneName ??
                    (_loadingZones ? "Loading..." : "—"),
                locked: true,
              )
                  : _buildDropdown<_ZoneModel>(
                hint: _loadingZones
                    ? "Loading zones..."
                    : "Select Zone",
                value: _selectedZone,
                items: _zones
                    .map((z) => DropdownMenuItem<_ZoneModel>(
                  value: z,
                  child: Text(z.name),
                ))
                    .toList(),
                onChanged: (z) {
                  setState(() {
                    _selectedZone = z;
                    _selectedTown = null;
                    _filteredTowns = [];
                  });
                  if (z != null) _fetchTownsByZone(z.id);
                },
              ),
              _sectionGap(),

              // ── Town ──────────────────────────────────────────────
              _label("Town", locked: _townIsLocked),
              _townIsLocked
                  ? _buildReadOnlyField(
                _lockedTownName ??
                    (_loadingTowns ? "Loading..." : "—"),
                locked: true,
              )
                  : _buildDropdown<_TownModel>(
                hint: _loadingTowns
                    ? "Loading towns..."
                    : (_selectedZone == null
                    ? "Select zone first"
                    : "Select Town"),
                value: _selectedTown,
                items: _filteredTowns
                    .map((t) => DropdownMenuItem<_TownModel>(
                  value: t,
                  child: Text(t.name),
                ))
                    .toList(),
                onChanged: _selectedZone == null
                    ? null
                    : (t) => setState(() => _selectedTown = t),
              ),
              _sectionGap(),

              // ── Map ───────────────────────────────────────────────
              if (_currentLocation != null) ...[
                _label("Location"),
                ClipRRect(
                  borderRadius: FrontendConfigs.kAppBorder,
                  child: SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_lat != 0 ? _lat : _currentLocation!.latitude,
                            _lng != 0 ? _lng : _currentLocation!.longitude),
                        zoom: 14,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (GoogleMapController ctrl) async {
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
                    side: BorderSide(
                        color: FrontendConfigs.kPrimaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: FrontendConfigs.kAppBorder,
                    ),
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_locationSet) ...[
                _label("Shop Address (from map)"),
                TextFormField(
                  controller: _shopAddressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "Shop Address",
                    hintStyle: TextStyle(
                      color: FrontendConfigs.kAuthTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(Icons.place_outlined,
                        color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: FrontendConfigs.kAppBorder,
                      borderSide: BorderSide.none,
                    ),
                    fillColor: FrontendConfigs.kTextFieldColor,
                    filled: true,
                    helperText:
                    "Auto-filled from map · you can edit if needed",
                    helperStyle: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (!_locationSet) const SizedBox(height: 20),

              // ── Cancel / Submit ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: FrontendConfigs.kAppBorder,
                        ),
                        side: BorderSide(
                            color: FrontendConfigs.kPrimaryColor),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: FrontendConfigs.kPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: FrontendConfigs.kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: FrontendConfigs.kAppBorder,
                        ),
                      ),
                      child: Text(
                        "Add $_typeLabel",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared Field Helpers ──────────────────────────────────────────────────

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

  Widget _sectionGap() => const SizedBox(height: 10);

  Widget _label(String text, {bool locked = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: CustomText(
      text: text,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: locked ? Colors.grey.shade500 : Colors.black87,
    ),
  );

  Widget _buildReadOnlyField(String value, {bool locked = false}) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: FrontendConfigs.kAppBorder,
        color: locked ? Colors.grey.shade200 : FrontendConfigs.kTextFieldColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (locked)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.lock_outline,
                  size: 16, color: Colors.grey.shade500),
            ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: locked ? Colors.grey.shade600 : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: FrontendConfigs.kAppBorder,
        color: FrontendConfigs.kTextFieldColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(
                  color: FrontendConfigs.kAuthTextColor, fontSize: 14)),
          value: value,
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down,
              color: FrontendConfigs.kAuthTextColor),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
          borderRadius: FrontendConfigs.kAppBorder,
        ),
      ),
    );
  }

  // ── Image Picker Helpers ──────────────────────────────────────────────────

  Widget _buildImagePicker({
    required File? image,
    required String title,
    required ValueChanged<File> onImageChanged,
    required VoidCallback onCrop,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: () => _showImagePickerBottomSheet(
            context,
            title: title,
            onImageChanged: onImageChanged,
          ),
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: FrontendConfigs.kAppBorder,
              color: FrontendConfigs.kTextFieldColor,
              border: Border.all(color: Colors.grey.shade300, width: 1),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FrontendConfigs.kPrimaryColor
                        .withValues(alpha: 0.1),
                  ),
                  child: Icon(CupertinoIcons.arrow_up_doc,
                      color: FrontendConfigs.kPrimaryColor, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  "Click to upload or drag and drop",
                  style: TextStyle(
                    color: FrontendConfigs.kPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "JPG, PNG etc (max. 10MB)",
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        if (image != null)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _imageActionButton(
                    icon: Icons.crop, tooltip: 'Crop', onTap: onCrop),
                const SizedBox(width: 6),
                _imageActionButton(
                    icon: Icons.tune, tooltip: 'Edit', onTap: onEdit),
                const SizedBox(width: 6),
                _imageActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Remove',
                    onTap: onRemove),
              ],
            ),
          ),
      ],
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

  void _showImagePickerBottomSheet(BuildContext context,
      {required String title, required ValueChanged<File> onImageChanged}) {
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
    await picker.pickImage(imageQuality: 85, source: source);
    if (pickedFile == null) return;
    final bytes = await File(pickedFile.path).readAsBytes();
    await _openProEditor(bytes, onImageChanged: onImageChanged);
  }

  Future<void> _cropOrEditImage() async {
    if (_profileImage == null) return;
    final bytes = await _profileImage!.readAsBytes();
    await _openProEditor(
      bytes,
      onImageChanged: (file) => setState(() => _profileImage = file),
    );
  }

  Future<void> _openProEditor(Uint8List bytes,
      {required ValueChanged<File> onImageChanged}) async {
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
      final saved = await File(path).writeAsBytes(result!);
      onImageChanged(saved);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _marketNameController.dispose();
    _bazarNameController.dispose();
    _roadNameController.dispose();
    _streetNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }
}