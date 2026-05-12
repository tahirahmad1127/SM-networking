import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sm_networking/application/retailer_bloc/retailer_bloc.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/infrastructure/model/add_retailer.dart';
import 'package:sm_networking/presentation/elements/app_button.dart';
import 'package:sm_networking/presentation/elements/auth_field.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../application/retailer_provider.dart';
import '../../../configurations/frontend_configs.dart';
import '../../../infrastructure/model/add_recovery.dart';
import '../../../infrastructure/model/banks.dart';
import '../../../infrastructure/services/retailers_cache.dart';
import '../../../injection_container.dart';
import '../../../infrastructure/services/Retailer.dart';
import '../../elements/custom_text.dart';
import '../../elements/processing_widget.dart';

class AddRecoveryView extends StatefulWidget {
  final String retailerId; // Pass retailer ID when navigating to this screen

  const AddRecoveryView({super.key, required this.retailerId});

  @override
  State<AddRecoveryView> createState() => _AddRecoveryViewState();
}

class _AddRecoveryViewState extends State<AddRecoveryView> {
  TextEditingController _paymentController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  File? receiptImage;
  String? selectedBankId;
  String? selectedBankName;
  DateTime? selectedDate;
  bool isLoading = false;

  List<BankModel> banksList = [];
  late RetailerBloc _retailerBloc;

  @override
  void initState() {
    super.initState();
    _retailerBloc = sl<RetailerBloc>();

    // Load cached banks immediately
    loadCachedBanks();

    // Fetch fresh banks from API
    _retailerBloc.add(const GetAllBanksEvent());
  }

  Future<void> loadCachedBanks() async {
    final cachedBanks = await RetailerCacheService.getCachedBanks();
    if (cachedBanks != null && cachedBanks.isNotEmpty) {
      setState(() {
        banksList = cachedBanks;
      });
    }
  }


  @override
  void dispose() {
    _paymentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: 'Add Recovery', showText: true),
      body: BlocProvider.value(
        value: _retailerBloc,
        child: BlocListener<RetailerBloc, RetailerState>(
          listener: (context, state) {
            if (state is BanksLoaded) {
              setState(() {
                banksList = state.model.banks;
              });
            } else if (state is BanksFailed) {
              getFlushBar(context, title: state.message);
            } else if (state is RecoveryAdded) {
              getFlushBar(context, title: "Recovery added successfully!");
              // Navigate back or clear form
              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              });
            } else if (state is RecoveryFailed) {
              getFlushBar(context, title: state.message);
            }
          },
          child: BlocBuilder<RetailerBloc, RetailerState>(
            builder: (context, state) {
              return LoadingOverlay(
                isLoading: state is BanksLoading || state is RecoveryLoading,
                progressIndicator: const ProcessingWidget(),
                color: Colors.transparent,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Bank Selection Dropdown (Dynamic from API)
                        Container(
                          height: 56,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            borderRadius: FrontendConfigs.kAppBorder,
                            color: FrontendConfigs.kTextFieldColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                elevation: 0,
                                borderRadius: BorderRadius.circular(12),
                                isExpanded: true,
                                value: selectedBankId,
                                hint: Text(
                                  banksList.isEmpty ? "Loading banks..." : "Select Bank",
                                  style: TextStyle(
                                    color: FrontendConfigs.kAuthTextColor,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_drop_down),
                                items: banksList.map((BankModel bank) {
                                  return DropdownMenuItem<String>(
                                    value: bank.id,
                                    child: CustomText(
                                      text: bank.name,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: FrontendConfigs.kAuthTextColor,
                                    ),
                                  );
                                }).toList(),
                                onChanged: banksList.isEmpty ? null : (newValue) {
                                  setState(() {
                                    selectedBankId = newValue;
                                    selectedBankName = banksList
                                        .firstWhere((bank) => bank.id == newValue)
                                        .name;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Payment Amount Field
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            controller: _paymentController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: "Payment Amount",
                              hintStyle: TextStyle(
                                color: FrontendConfigs.kAuthTextColor,
                                fontSize: 14,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: FrontendConfigs.kAppBorder,
                                borderSide: BorderSide.none,
                              ),
                              fillColor: FrontendConfigs.kTextFieldColor,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description Field
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: "Description",
                            hintStyle: TextStyle(
                              color: FrontendConfigs.kAuthTextColor,
                              fontSize: 14,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: FrontendConfigs.kAppBorder,
                              borderSide: BorderSide.none,
                            ),
                            fillColor: FrontendConfigs.kTextFieldColor,
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Upload Receipt (Take Picture)
                        InkWell(
                          onTap: () {
                            showImagePickerBottomSheet(context);
                          },
                          child: Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: FrontendConfigs.kAppBorder,
                              color: FrontendConfigs.kTextFieldColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      receiptImage == null
                                          ? "Upload Receipt (Optional)"
                                          : "Receipt Uploaded Successfully",
                                      style: TextStyle(
                                        color: FrontendConfigs.kAuthTextColor,
                                        fontSize: 14,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.camera)
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Date Picker
                        InkWell(
                          onTap: () {
                            selectDate(context);
                          },
                          child: Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: FrontendConfigs.kAppBorder,
                              color: FrontendConfigs.kTextFieldColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate == null
                                        ? "Select Date"
                                        : DateFormat('dd/MM/yyyy').format(selectedDate!),
                                    style: TextStyle(
                                      color: FrontendConfigs.kAuthTextColor,
                                      fontSize: 14,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today)
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Add Recovery Button
                        AppButton(
                          onPressed: () async {
                            // Validate bank
                            if (selectedBankId == null) {
                              getFlushBar(context, title: "Please select a bank.");
                              return;
                            }

                            // Validate payment amount
                            if (_paymentController.text.isEmpty) {
                              getFlushBar(context, title: "Payment amount cannot be empty.");
                              return;
                            }

                            double? amount = double.tryParse(_paymentController.text);
                            if (amount == null || amount <= 0) {
                              getFlushBar(context, title: "Please enter a valid payment amount.");
                              return;
                            }

                            // Validate date
                            if (selectedDate == null) {
                              getFlushBar(context, title: "Please select a valid date.");
                              return;
                            }

                            // Validate details
                            if (_descriptionController.text.trim().isEmpty) {
                              getFlushBar(context, title: "Please enter payment details.");
                              return;
                            }

                            // Create AddRecoveryModel
                            final recoveryModel = AddRecoveryModel(
                              retailerId: widget.retailerId,
                              bankId: selectedBankId!,
                              amount: amount,
                              date: selectedDate!.toIso8601String(),
                              details: _descriptionController.text.trim(),
                              imagePath: receiptImage?.path, // optional
                            );

                            // Dispatch event
                            _retailerBloc.add(AddRecoveryEvent(recoveryModel));
                          },
                          btnLabel: 'Add Recovery',
                        ),
                        const SizedBox(height: 20),
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

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FrontendConfigs.kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void showImagePickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              CustomText(
                text: "Upload Receipt",
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              const SizedBox(height: 20),

              // Camera Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FrontendConfigs.kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.camera,
                    color: FrontendConfigs.kPrimaryColor,
                  ),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  getReceiptImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),

              // Gallery Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FrontendConfigs.kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.photo,
                    color: FrontendConfigs.kPrimaryColor,
                  ),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  getReceiptImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future getReceiptImage(ImageSource source) async {
    ImagePicker picker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await picker.pickImage(
      imageQuality: 20,
      source: source,
    );

    setState(() {
      if (pickedFile != null) {
        receiptImage = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }
}