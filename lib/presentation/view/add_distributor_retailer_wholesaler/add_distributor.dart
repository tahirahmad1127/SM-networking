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

// ─── Models ──────────────────────────────────────────────────────────────────

class ZoneModel {
  final String id;
  final String name;
  final String locationId;

  ZoneModel({required this.id, required this.name, required this.locationId});

  factory ZoneModel.fromJson(Map<String, dynamic> json) => ZoneModel(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        locationId: json['locationId'] ?? '',
      );
}

class TownModel {
  final String id;
  final String name;
  final String locationId;
  final String zoneId;

  TownModel(
      {required this.id,
      required this.name,
      required this.locationId,
      required this.zoneId});

  factory TownModel.fromJson(Map<String, dynamic> json) => TownModel(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        locationId: json['locationId'] ?? '',
        zoneId: (json['zoneId'] is Map)
            ? (json['zoneId']['_id'] ?? '')
            : (json['zoneId'] ?? ''),
      );
}

// ─── View ─────────────────────────────────────────────────────────────────────

class AddDistributorView extends StatefulWidget {
  const AddDistributorView({super.key});

  @override
  State<AddDistributorView> createState() => _AddDistributorViewState();
}

class _AddDistributorViewState extends State<AddDistributorView> {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _proprietorNameController = TextEditingController();
  final _distributionNameController = TextEditingController();
  final _salesIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopAddressController = TextEditingController();

  // ── Images ───────────────────────────────────────────────────────────────
  File? _profileImage;
  File? _chequeImage;

  // ── Map ──────────────────────────────────────────────────────────────────
  final Set<Marker> _markers = {};
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
  bool _obscurePassword = true;

  // ── Inline field errors ───────────────────────────────────────────────────
  String? _proprietorNameError;
  String? _distributionNameError;
  String? _salesIdError;
  String? _emailError;
  String? _passwordError;
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
      final latLng = LatLng(pos.latitude, pos.longitude);
      _currentLocation = latLng;
      _lat = pos.latitude;
      _lng = pos.longitude;
      _markers.add(Marker(markerId: MarkerId('current'), position: latLng));
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
      ..add(Marker(markerId: MarkerId('picked'), position: LatLng(_lat, _lng)));
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
          final list =
              (data['data'] as List).map((e) => ZoneModel.fromJson(e)).toList();
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
          final list =
              (data['data'] as List).map((e) => TownModel.fromJson(e)).toList();
          if (!mounted) return;
          setState(() => _filteredTowns = list);

          if (_townIsLocked && _lockedTownId != null) {
            final match = list.where((t) => t.id == _lockedTownId).firstOrNull;
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
    // ── Validate all fields inline ────────────────────────────────────────
    bool hasError = false;

    // Proprietor Name: required, letters and spaces only
    final proprietorName = _proprietorNameController.text.trim();
    if (proprietorName.isEmpty) {
      _proprietorNameError = "Fill please";
      hasError = true;
    } else if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(proprietorName)) {
      _proprietorNameError =
          "Name must contain letters only (no numbers or special characters)";
      hasError = true;
    } else {
      _proprietorNameError = null;
    }

    // Distribution Name: required, letters and spaces only
    final distributionName = _distributionNameController.text.trim();
    if (distributionName.isEmpty) {
      _distributionNameError = "Fill please";
      hasError = true;
    } else if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(distributionName)) {
      _distributionNameError =
          "Name must contain letters only (no numbers or special characters)";
      hasError = true;
    } else {
      _distributionNameError = null;
    }

    // Sales ID: required, alphanumeric only
    final salesId = _salesIdController.text.trim();
    if (salesId.isEmpty) {
      _salesIdError = "Fill please";
      hasError = true;
    } else if (!RegExp(r"^[a-zA-Z0-9]+$").hasMatch(salesId)) {
      _salesIdError =
          "Sales ID must contain only letters and numbers (no special characters)";
      hasError = true;
    } else {
      _salesIdError = null;
    }

    // Email: required, valid format
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = "Fill please";
      hasError = true;
    } else if (!RegExp(r"^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      _emailError = "Please enter a valid email address";
      hasError = true;
    } else {
      _emailError = null;
    }

    // Password: required, minimum 6 characters
    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = "Fill please";
      hasError = true;
    } else if (password.length < 6) {
      _passwordError = "Password must be at least 6 characters";
      hasError = true;
    } else {
      _passwordError = null;
    }

    // Phone: required, must start with 03 (11 chars) or +923 (13 chars)
    final phoneRaw = _phoneController.text.trim();
    if (phoneRaw.isEmpty) {
      _phoneError = "Fill please";
      hasError = true;
    } else {
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

      final registerBody = <String, dynamic>{
        'name': _proprietorNameController.text.trim(),
        'distributionName': _distributionNameController.text.trim(),
        'salesId': _salesIdController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
        'zone': _selectedZone!.id,
        'town': _selectedTown!.id,
        if (_shopAddressController.text.trim().isNotEmpty)
          'shopAddress1': _shopAddressController.text.trim(),
      };

      String? newUserId;

      final hasImage = _profileImage != null || _chequeImage != null;

      if (hasImage) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${BackendConfigs.apiUrl}sale-user/register'),
        );
        request.headers['Authorization'] = 'Bearer $token';

        registerBody.forEach((key, value) {
          if (value != null) request.fields[key] = value.toString();
        });

        if (_profileImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            _profileImage!.path,
          ));
        }
        if (_chequeImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'securityChequeImage',
            _chequeImage!.path,
          ));
        }

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);

        final responseBody = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          newUserId = responseBody['data']?['_id'] as String? ??
              responseBody['data']?['id'] as String?;
        } else {
          if (mounted) {
            final msg = responseBody['msg'] ??
                responseBody['message'] ??
                responseBody['error'] ??
                'Registration failed (${response.statusCode}).';
            getFlushBar(context, title: msg.toString());
          }
          return;
        }
      } else {
        final result = await _api.postEither(
          endPoint: 'sale-user/register',
          isRequiredHeader: true,
          hasBody: true,
          body: registerBody,
          header: authHeader,
        );

        bool registrationFailed = false;
        result.fold(
          (error) {
            registrationFailed = true;
            if (mounted) {
              getFlushBar(context,
                  title: error.error ?? 'Something went wrong.');
            }
          },
          (data) {
            newUserId = data['data']?['_id'] as String? ??
                data['data']?['id'] as String?;
          },
        );
        if (registrationFailed) return;
      }

      if (newUserId?.isNotEmpty ?? false) {
        await _api.postEither(
          endPoint: 'sale-user/location/$newUserId',
          isRequiredHeader: true,
          hasBody: true,
          body: {
            'lat': _lat,
            'lng': _lng,
            'shopLocation': {
              'lat': _lat,
              'lng': _lng,
            },
          },
          header: authHeader,
        );
      }

      if (mounted && newUserId != null) {
        final newDistributor = Distributor(
          id: newUserId,
          salesId: _salesIdController.text.trim(),
          name: _proprietorNameController.text.trim(),
          distributionName: _distributionNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          isActive: true,
          isDeleted: false,
          town: DistributorRef(
            id: _selectedTown!.id,
            name: _selectedTown!.name,
          ),
          zone: DistributorRef(
            id: _selectedZone!.id,
            name: _selectedZone!.name,
          ),
          shopLocation:
              _locationSet ? DistributorLocation(lat: _lat, lng: _lng) : null,
        );

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentList = List<Distributor>.from(
          userProvider.getSalesUserDetails()?.distributors ?? [],
        );
        currentList.add(newDistributor);
        userProvider.updateDistributors(currentList);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        getFlushBar(context, title: 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: 'Add Distributors', showText: true),
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
                      onCrop: () => _cropImage(isProfile: true),
                      onEdit: () => _editImage(isProfile: true),
                      onRemove: () => setState(() => _profileImage = null),
                    ),
                    _sectionGap(),

                    // ── Security Cheque Image ──────────────────────────────
                    _label("Security Cheque Image (Optional)"),
                    _buildImagePicker(
                      image: _chequeImage,
                      title: "Upload Cheque Image",
                      onImageChanged: (file) =>
                          setState(() => _chequeImage = file),
                      onCrop: () => _cropImage(isProfile: false),
                      onEdit: () => _editImage(isProfile: false),
                      onRemove: () => setState(() => _chequeImage = null),
                    ),
                    _sectionGap(),

                    // ── Proprietor Name ────────────────────────────────────
                    _label("Proprietor Name"),
                    TextFormField(
                      controller: _proprietorNameController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))
                      ],
                      onChanged: (_) {
                        if (_proprietorNameError != null) {
                          setState(() => _proprietorNameError = null);
                        }
                      },
                      decoration: _fieldDecoration("Proprietor Name").copyWith(
                        errorText: _proprietorNameError,
                        errorMaxLines: 2,
                      ),
                    ),
                    _sectionGap(),

                    // ── Distribution Name ──────────────────────────────────
                    _label("Distribution Name"),
                    TextFormField(
                      controller: _distributionNameController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))
                      ],
                      onChanged: (_) {
                        if (_distributionNameError != null) {
                          setState(() => _distributionNameError = null);
                        }
                      },
                      decoration:
                          _fieldDecoration("Distribution Name").copyWith(
                        errorText: _distributionNameError,
                        errorMaxLines: 2,
                      ),
                    ),
                    _sectionGap(),

                    // ── Sales ID ───────────────────────────────────────────
                    _label("Sales ID"),
                    TextFormField(
                      controller: _salesIdController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'))
                      ],
                      onChanged: (_) {
                        if (_salesIdError != null) {
                          setState(() => _salesIdError = null);
                        }
                      },
                      decoration:
                          _fieldDecoration("Enter unique Sales ID").copyWith(
                        errorText: _salesIdError,
                        errorMaxLines: 2,
                      ),
                    ),
                    _sectionGap(),

                    // ── Email ──────────────────────────────────────────────
                    _label("Email"),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                      decoration: _fieldDecoration("Email").copyWith(
                        errorText: _emailError,
                        errorMaxLines: 2,
                      ),
                    ),
                    _sectionGap(),

                    // ── Password ───────────────────────────────────────────
                    _label("Password"),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Password",
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
                            horizontal: 16, vertical: 16),
                        errorText: _passwordError,
                        errorMaxLines: 2,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: FrontendConfigs.kAuthTextColor,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    _sectionGap(),

                    // ── Phone Number ───────────────────────────────────────
                    _label("Phone Number"),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        // Allow digits and a leading '+' only
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        LengthLimitingTextInputFormatter(13),
                      ],
                      onChanged: (_) {
                        if (_phoneError != null) {
                          setState(() => _phoneError = null);
                        }
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
                    _label("Town", locked: _townIsLocked),
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

                    // ── Shop Location ──────────────────────────────────────
                    _label("Shop Location"),
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

                    if (_locationSet) ...[
                      _label("Shop Address"),
                      TextFormField(
                        controller: _shopAddressController,
                        readOnly: false,
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

                    // ── Cancel / Add Distributor ───────────────────────────
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
                            child: const Text(
                              "Add Distributor",
                              style: TextStyle(
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

  // ── Shared Field Helpers (matching add_recovery.dart style) ───────────────

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

  /// Label above each field. Locked labels render in grey.
  Widget _label(String text, {bool locked = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: CustomText(
          text: text,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: locked ? Colors.grey.shade500 : Colors.black87,
        ),
      );

  /// Grey read-only tile for locked / auto-fetched values.
  Widget _buildReadOnlyField(String value, {bool locked = false}) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: FrontendConfigs.kAppBorder,
        color: locked ? Colors.grey.shade200 : FrontendConfigs.kTextFieldColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          if (locked) ...[
            const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
          ],
          Text(
            value.isNotEmpty ? value : '—',
            style: TextStyle(
              color: locked
                  ? Colors.grey.shade500
                  : (value.isNotEmpty
                      ? Colors.black87
                      : FrontendConfigs.kAuthTextColor),
              fontSize: 14,
              fontWeight: FontWeight.w400,
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
    ValueChanged<T?>? onChanged,
  }) {
    final validValue = items.any((i) => i.value == value) ? value : null;
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: FrontendConfigs.kAppBorder,
        color: FrontendConfigs.kTextFieldColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            elevation: 0,
            borderRadius: BorderRadius.circular(12),
            isExpanded: true,
            value: validValue,
            hint: Text(
              hint,
              style: TextStyle(
                color: FrontendConfigs.kAuthTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // ── Image Picker Widget (matching add_recovery.dart) ─────────────────────

  /// Full image-picker tile with upload placeholder OR preview + action buttons.
  /// [title] is shown in the bottom sheet header.
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

        // Edit / Crop / Remove actions — only shown when image is selected
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

  // ── Bottom Sheet (Camera / Gallery) ──────────────────────────────────────

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
            // Drag handle
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
                  color: FrontendConfigs.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.camera,
                    color: FrontendConfigs.kPrimaryColor),
              ),
              title: const Text('Camera',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndEdit(
                    source: ImageSource.camera, onImageChanged: onImageChanged);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FrontendConfigs.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.photo,
                    color: FrontendConfigs.kPrimaryColor),
              ),
              title: const Text('Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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

  // ── Image Editing Helpers ─────────────────────────────────────────────────

  /// Pick from [source], then open ProImageEditor.
  Future<void> _pickAndEdit({
    required ImageSource source,
    required ValueChanged<File> onImageChanged,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(imageQuality: 60, source: source);
    if (pickedFile == null) return;
    final bytes = await File(pickedFile.path).readAsBytes();
    await _openProEditor(bytes, onImageChanged: onImageChanged);
  }

  /// Re-open editor in crop/rotate mode for an already-selected image.
  Future<void> _cropImage({required bool isProfile}) async {
    final image = isProfile ? _profileImage : _chequeImage;
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _openProEditor(
      bytes,
      onImageChanged: (file) => setState(() {
        if (isProfile) {
          _profileImage = file;
        } else {
          _chequeImage = file;
        }
      }),
    );
  }

  /// Re-open the full editor for an already-selected image.
  Future<void> _editImage({required bool isProfile}) async {
    final image = isProfile ? _profileImage : _chequeImage;
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _openProEditor(
      bytes,
      onImageChanged: (file) => setState(() {
        if (isProfile) {
          _profileImage = file;
        } else {
          _chequeImage = file;
        }
      }),
    );
  }

  /// Opens ProImageEditor and saves the result via [onImageChanged].
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

      // Re-compress after editor to keep payload small (fixes 413 when both images sent)
      final compressed = await FlutterImageCompress.compressWithList(
        result!,
        quality: 50,
        format: CompressFormat.jpeg,
      );

      final saved = await File(path).writeAsBytes(compressed);
      onImageChanged(saved);
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _proprietorNameController.dispose();
    _distributionNameController.dispose();
    _salesIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }
}
