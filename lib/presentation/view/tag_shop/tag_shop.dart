import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sm_networking/application/retailer_bloc/retailer_bloc.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/infrastructure/model/add_retailer.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/retailer.dart';
import 'package:sm_networking/infrastructure/services/upload_file_services.dart';
import 'package:sm_networking/presentation/elements/app_button.dart';
import 'package:sm_networking/presentation/elements/auth_field.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/navigation_dialog.dart';
import 'package:sm_networking/presentation/view/category_listing/category_listing_view.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:place_picker/entities/location_result.dart';
import 'package:place_picker/widgets/place_picker.dart';
import 'package:provider/provider.dart';

import '../../../application/locaition_helper.dart';
import '../../../application/location.dart';
import '../../../application/retailer_provider.dart';
import '../../../application/visit_bloc/visit_bloc.dart';
import '../../../application/visit_provider.dart';
import '../../../configurations/frontend_configs.dart';
import '../../../infrastructure/model/visit.dart';
import '../../../infrastructure/services/Category.dart';
import '../../../injection_container.dart';
import '../../elements/custom_text.dart';
import '../../elements/my_logger.dart';
import '../../elements/processing_widget.dart';
import '../categories/categories_view.dart';

class TagShopView extends StatefulWidget {
  const TagShopView({super.key});

  @override
  State<TagShopView> createState() => _TagShopViewState();
}

class _TagShopViewState extends State<TagShopView> {
  TextEditingController _nameController = TextEditingController();

  TextEditingController _shopNameController = TextEditingController();

  TextEditingController _addressController = TextEditingController();

  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _cnicNumberController = TextEditingController();
  File? image;
  Set<Marker> markers = {};
  LatLng? currentLocation;
  GoogleMapController? mapController;
  String? selectedCategory;
  double lat = 0.0;
  double lng = 0.0;
  final Completer<GoogleMapController> _controller = Completer();
  bool isLoading = false;
  var categoryList = [
    'General Store',
    'Medical Store/Pharmacy',
    'Diaper House',
    'Disposable',
    'Wholesale / Distributor',
    'Kiosk',
    'Mart / Super Market',
    'Bakery',
    'Restaurant',
    'Educational Institution',
    'Office',
    'Hospital',
    'Horeca Reseller',
    'Public Kitchen',
    'Petro Mart',
    'Dhaba',
    'Cafe',
  ];

  @override
  void initState() {
    determinePosition().then((value) {
      currentLocation = LatLng(value.latitude!, value.longitude!);
      markers.add(Marker(
          markerId: MarkerId(value.hashCode.toString()),
          position: LatLng(value.latitude!, value.longitude!)));
      lat = value.latitude;
      lng = value.longitude;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    var retailer = Provider.of<RetailerProvider>(context);
    return Scaffold(
      appBar: customAppBar(context, text: 'Tag Customer', showText: true),
      body: currentLocation == null
          ? const Center(
        child: ProcessingWidget(),
      )
          : BlocProvider(
        create: (context) => sl<RetailerBloc>(),
        child: BlocListener<RetailerBloc, RetailerState>(
          listener: (context, state) {
            if (state is RetailerAdded) {
              retailer.saveRetailer(state.model);
              showNavigationDialog(
                context,
                message: "Customer has been tagged successfully.",
                buttonText: "Okay",
                navigation: () async {
                  Navigator.pop(context); // Close the dialog

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: ProcessingWidget()),
                  );

                  final user = Provider.of<UserProvider>(context, listen: false);
                  final visitProvider = Provider.of<VisitProvider>(context, listen: false);
                  final locationProvider = Provider.of<LocationProvider>(context, listen: false);

                  try {
                    // Get current location for visit
                    if (currentLocation != null) {
                      AppLogger.debug("🏪 Starting visit for newly tagged shop");
                      AppLogger.debug("📍 Location: ${currentLocation!.latitude}, ${currentLocation!.longitude}");

                      // Get INITIAL fresh location
                      final position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );

                      AppLogger.debug("📍 Initial GPS location obtained");
                      AppLogger.debug("   Location: ${position.latitude}, ${position.longitude}");
                      AppLogger.debug("   Accuracy: ${position.accuracy.toStringAsFixed(2)}m");

                      // Start visit WITHOUT image (pass empty string or null)
                      // Since this is a new shop tagging, we don't need separate visit image
                      await visitProvider.setStartVisit(
                        location: currentLocation!,
                        accuracy: position.accuracy,
                        imagePath: "No Image",
                        isNewShop: true,
                        onLocationCheckCallback: () async {
                          // CRITICAL: Check if visit is cleared before doing anything
                          if (visitProvider.startVisit == null || visitProvider.visitLocation == null) {
                            AppLogger.debug("⚠️ Visit data cleared - skipping callback");
                            return;
                          }

                          // Fetch FRESH GPS location every time timer fires!
                          Position freshPosition;
                          try {
                            freshPosition = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high,
                              timeLimit: const Duration(seconds: 5),
                            );

                            AppLogger.debug("📍 Fresh GPS location obtained in timer callback");
                            AppLogger.debug("   Location: ${freshPosition.latitude}, ${freshPosition.longitude}");
                            AppLogger.debug("   Accuracy: ${freshPosition.accuracy.toStringAsFixed(2)}m");
                          } catch (e) {
                            AppLogger.debug("❌ Failed to get fresh GPS location: $e");
                            return;
                          }

                          final currentLoc = LatLng(freshPosition.latitude, freshPosition.longitude);

                          // Update LocationProvider with fresh location
                          locationProvider.setLatLng(currentLoc);

                          // Check distance with FRESH location and accuracy
                          await visitProvider.checkAndAutoLogVisit(
                            currentLocation: currentLoc,
                            currentAccuracy: freshPosition.accuracy,
                            onShowNotification: (message) {
                              // Show notification to user
                              if (context.mounted) {
                                getFlushBar(context, title: message);
                              }
                            },
                            onAutoLogVisit: () async {
                              // Double-check visit still exists before auto-logging
                              if (visitProvider.startVisit == null) {
                                AppLogger.debug("⚠️ Visit cleared before auto-log");
                                return;
                              }

                              // Auto-log the visit
                              final retailerProvider = Provider.of<RetailerProvider>(context, listen: false);
                              final userProvider = Provider.of<UserProvider>(context, listen: false);

                              final selectedRetailer = retailerProvider.getRetailer();
                              final userDetails = userProvider.getSalesUserDetails()?.user;
                              final startVisit = await visitProvider.getStartVisit();

                              if (selectedRetailer != null && userDetails != null && startVisit != null) {
                                final visit = VisitModel(
                                  retailerId: selectedRetailer.id.toString(),
                                  salesPersonId: userDetails.id.toString(),
                                  startTime: startVisit.toIso8601String(),
                                  endTime: DateTime.now().toIso8601String(),
                                  date: DateTime.now().toString().split(' ')[0],
                                  image: visitProvider.visitImage ?? "", // Use empty string if no image
                                );

                                // Check if context is still valid
                                if (context.mounted) {
                                  context.read<VisitBloc>().add(AddVisitEvent(visit));
                                  await visitProvider.clearVisitData();
                                  AppLogger.debug("✅ Visit auto-logged for newly tagged shop");
                                }
                              }
                            },
                          );
                        },
                      );

                      AppLogger.debug("✅ Visit started successfully for new shop");
                    } else {
                      AppLogger.debug("⚠️ No current location available to start visit");
                    }

                    Navigator.of(context).pop(); // Remove loader dialog

                    // Navigate to category listing
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryListingView(
                          showCart: true,
                        ),
                      ),
                    );

                    // Show success message
                    if (context.mounted) {
                      getFlushBar(context, title: "Visit Started Successfully");
                    }

                  } catch (e) {
                    Navigator.of(context).pop(); // Remove loader dialog
                    AppLogger.debug('❌ Exception while starting visit: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error starting visit: $e')),
                    );
                  }
                },
                secondButtonText: "secondButtonText",
                showSecondButton: false,
              );

            } else if (state is RetailerFailed) {
              getFlushBar(context, title: state.message.toString());
            }
          },
          child: BlocBuilder<RetailerBloc, RetailerState>(
            builder: (context, state) {
              return LoadingOverlay(
                isLoading: state is RetailerLoading,
                progressIndicator: const ProcessingWidget(),
                color: Colors.transparent,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                            controller: _nameController,
                            text: "Customer Name",
                            onTap: () {},
                            keyBoardType: TextInputType.text),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomTextField(
                            controller: _shopNameController,
                            text: "Shop Name",
                            onTap: () {},
                            keyBoardType: TextInputType.text),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomTextField(
                            controller: _addressController,
                            onTap: () {},
                            text: "Shop Address",
                            maxLines: 2,
                            keyBoardType: TextInputType.text),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomText(
                            text: "Select Location from Map",
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                        const SizedBox(
                          height: 8,
                        ),
                        SizedBox(
                          height: 245,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: GoogleMap(
                              zoomControlsEnabled: false,
                              markers: markers,
                              onTap: (val) {
                                showPlacePicker();
                              },
                              mapType: MapType.normal,
                              mapToolbarEnabled: false,
                              initialCameraPosition: CameraPosition(
                                  target: currentLocation!,
                                  zoom: 16,
                                  tilt: 85,
                                  bearing: 20),
                              onMapCreated:
                                  (GoogleMapController controller) async {
                                _controller.complete(controller);
                                mapController = await _controller.future;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            keyboardType: TextInputType.phone,
                            controller: _phoneNumberController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            decoration: InputDecoration(
                              hintText: "Customer Phone Number",
                              hintStyle:  TextStyle(
                                  color:  FrontendConfigs.kAuthTextColor,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w400),
                              border: OutlineInputBorder(
                                  borderRadius:
                                  FrontendConfigs.kAppBorder,
                                  borderSide: BorderSide.none),
                              fillColor: FrontendConfigs.kTextFieldColor,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            keyboardType: TextInputType.phone,
                            controller: _cnicNumberController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                            ],
                            decoration: InputDecoration(
                              hintText:
                              "Customer CNIC Number (without dashes)",
                              hintStyle:  TextStyle(
                                  color:  FrontendConfigs.kAuthTextColor,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w400),
                              border: OutlineInputBorder(
                                  borderRadius:
                                  FrontendConfigs.kAppBorder,
                                  borderSide: BorderSide.none),
                              fillColor: FrontendConfigs.kTextFieldColor,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () {
                            getProfileImage();
                          },
                          child: Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                borderRadius: FrontendConfigs.kAppBorder,
                                color: FrontendConfigs.kTextFieldColor),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(image == null
                                      ? "Take Picture"
                                      : "Image Captured Successfully",style: TextStyle(
                                      color:  FrontendConfigs.kAuthTextColor,
                                      fontSize: 14,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w400
                                  ),),
                                  const Icon(CupertinoIcons.camera)
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          height: 56,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              borderRadius: FrontendConfigs.kAppBorder,
                              color: FrontendConfigs.kTextFieldColor),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                elevation: 0,
                                borderRadius: BorderRadius.circular(12),
                                isExpanded: true,
                                value: selectedCategory,
                                hint: const Text("Select Category"),
                                icon: const Icon(Icons.arrow_drop_down),
                                items: categoryList.map((String items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: CustomText(
                                      text: items,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color:
                                      FrontendConfigs.kAuthTextColor,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedCategory = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        AppButton(
                          onPressed: () async {
                            if (_nameController.text.isEmpty) {
                              getFlushBar(context, title: "Retailer name cannot be empty.");
                              return;
                            }
                            if (_shopNameController.text.isEmpty) {
                              getFlushBar(context, title: "Shop name cannot be empty.");
                              return;
                            }
                            if (_addressController.text.isEmpty) {
                              getFlushBar(context, title: "Address cannot be empty.");
                              return;
                            }
                            // if (lat == 0.0) {
                            //   getFlushBar(context, title: "Kindly pick address from map.");
                            //   return;
                            // }
                            if (_phoneNumberController.text.isEmpty) {
                              getFlushBar(context, title: "Phone Number cannot be empty.");
                              return;
                            }
                            if (_phoneNumberController.text.length < 11) {
                              getFlushBar(context, title: "Phone Number is not valid.");
                              return;
                            }
                            if (selectedCategory == null) {
                              getFlushBar(context, title: "Kindly select shop category.");
                              return;
                            }

                            isLoading = true;
                            setState(() {});

                            try {
                              BlocProvider.of<RetailerBloc>(context).add(
                                AddRetailerEvent(
                                  AddRetailerModel(
                                    shopName: _shopNameController.text,
                                    shopCategory: selectedCategory,
                                    shopAddress2: "N/A",
                                    shopAddress1: _addressController.text,
                                    file: image?.path ?? "",
                                    name: _nameController.text,
                                    phoneNumber: _phoneNumberController.text,
                                    lat: lat.toString(),
                                    lng: lng.toString(),
                                    distance: "1",
                                    cnic: _cnicNumberController.text.isEmpty
                                        ? ""
                                        : _cnicNumberController.text,
                                    salesPersonId: user.getSalesUserDetails()!.user!.id.toString(),
                                    cityId: user.getSalesUserDetails()!.user!.zone.toString(),
                                  ),
                                ),
                              );
                            } catch (e) {
                              getFlushBar(context, title: e.toString());
                            } finally {
                              isLoading = false;
                              setState(() {});
                            }
                          },
                          btnLabel: 'Tag Customer',
                        ),

                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void showPlacePicker() async {
    LocationResult result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PlacePicker(
          "AIzaSyAuJYLmzmglhCpBYTn0BjbJhjWYg0fPEEA",
          displayLocation: currentLocation,
        )));
    lat = result.latLng!.latitude;
    lng = result.latLng!.longitude;
    markers.clear();
    setState(() {});
    markers.add(Marker(
        markerId: MarkerId(result.latLng!.latitude.toString()),
        position: LatLng(result.latLng!.latitude, result.latLng!.longitude)));

    mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(result.latLng!.latitude, result.latLng!.longitude),
        zoom: 12)));
    setState(() {});
    // Handle the result in your way
    print(result);
  }

  Future getProfileImage() async {
    ImagePicker picker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await picker.pickImage(
      imageQuality: 20,
      source: ImageSource.camera,
    );

    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }
}