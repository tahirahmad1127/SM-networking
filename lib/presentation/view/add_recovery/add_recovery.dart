import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:sm_networking/application/retailer_bloc/retailer_bloc.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:intl/intl.dart';

import '../../../application/user_provider.dart';
import '../../../configurations/frontend_configs.dart';
import '../../../infrastructure/model/add_recovery.dart';
import '../../../infrastructure/model/user.dart';
import '../../../injection_container.dart';
import '../../elements/custom_text.dart';
import '../../elements/processing_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USAGE: When navigating to this screen, pass the distributor's id so that
// the name, zone, and town are fetched automatically:
//
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => AddRecoveryView(distributorId: dist.id!),
//     ),
//   );
// ─────────────────────────────────────────────────────────────────────────────

class AddRecoveryView extends StatefulWidget {
  /// The id of the distributor whose "Add Recovery" button was tapped.
  final String distributorId;

  const AddRecoveryView({super.key, required this.distributorId});

  @override
  State<AddRecoveryView> createState() => _AddRecoveryViewState();
}

class _AddRecoveryViewState extends State<AddRecoveryView> {
  // ── Controllers ──────────────────────────────────────────────────────────
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _beneficiaryAccountNumberController =
  TextEditingController();
  final TextEditingController _beneficiaryAccountNameController =
  TextEditingController();
  final TextEditingController _beneficiaryBankNameController =
  TextEditingController();

  // ── Auto-fetched fields (no dropdowns) ───────────────────────────────────
  String? _distributorId;
  String? _distributorName;
  String? _zoneId;
  String? _zoneName;
  String? _townId;
  String? _townName;

  // ── Payment mode (still a dropdown) ─────────────────────────────────────
  String? selectedPaymentMode;

  DateTime selectedDate = DateTime.now();
  File? receiptImage;

  late RetailerBloc _retailerBloc;

  final List<String> paymentModes = [
    'Online Transfer',
    'Cash',
    'Cheque',
    'Bank Draft',
  ];

  bool get _requiresBankDetails =>
      selectedPaymentMode != null && selectedPaymentMode != 'Cash';

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _retailerBloc = sl<RetailerBloc>();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _autoFetchDistributorDetails());
  }

  /// Reads the distributor matching [widget.distributorId] from UserProvider
  /// and automatically populates name, zone, and town — no user input needed.
  void _autoFetchDistributorDetails() {
    final userModel = context.read<UserProvider>().getSalesUserDetails();
    final dist = userModel?.distributors?.firstWhere(
          (d) => d.id == widget.distributorId,
      orElse: () => Distributor(),
    );

    if (dist == null) return;

    setState(() {
      _distributorId = dist.id;
      _distributorName = (dist.distributionName?.isNotEmpty == true)
          ? dist.distributionName
          : (dist.name ?? '');
      _zoneId = dist.zone?.id;
      _zoneName = dist.zone?.name;
      _townId = dist.town?.id;
      _townName = dist.town?.name;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _branchCodeController.dispose();
    _beneficiaryAccountNumberController.dispose();
    _beneficiaryAccountNameController.dispose();
    _beneficiaryBankNameController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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

  /// A read-only display tile used in place of dropdowns for auto-fetched fields.
  /// When [locked] is true the field renders with a grey background and grey
  /// text to make it visually obvious that the value cannot be edited.
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
      child: Text(
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: 'Add Recovery', showText: true),
      body: BlocProvider.value(
        value: _retailerBloc,
        child: BlocListener<RetailerBloc, RetailerState>(
          listener: (context, state) {
            if (state is RecoveryAdded) {
              final srNo = state.model.srNo;
              getFlushBar(
                context,
                title: srNo.isNotEmpty
                    ? "Payment $srNo created successfully!"
                    : "Payment created successfully!",
              );
              final nav = Navigator.of(context);
              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted) {
                  nav.pop();
                  nav.pop();
                }
              });
            } else if (state is RecoveryFailed) {
              getFlushBar(context, title: state.message);
            }
          },
          child: BlocBuilder<RetailerBloc, RetailerState>(
            builder: (context, state) {
              return LoadingOverlay(
                isLoading: state is RecoveryLoading,
                progressIndicator: const ProcessingWidget(),
                color: Colors.transparent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Receipt Image ──────────────────────────────────
                      _label("Receipt Image"),
                      _buildReceiptImagePicker(),
                      _sectionGap(),

                      // ── Distribution Name (auto-fetched, read-only) ────
                      _label("Distributor Name", locked: true),
                      _buildReadOnlyField(_distributorName ?? '', locked: true),
                      _sectionGap(),

                      // ── Date (Cupertino wheel picker) ──────────────────
                      _label("Date"),
                      _buildDateField(context),
                      _sectionGap(),

                      // ── Amount ────────────────────────────────────────
                      _label("Amount"),
                      SizedBox(
                        height: 56,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: _fieldDecoration("Amount"),
                        ),
                      ),
                      _sectionGap(),

                      // ── Zone (auto-fetched, read-only) ─────────────────
                      _label("Zone", locked: true),
                      _buildReadOnlyField(_zoneName ?? '', locked: true),
                      _sectionGap(),

                      // ── Town (auto-fetched, read-only) ─────────────────
                      _label("Town", locked: true),
                      _buildReadOnlyField(_townName ?? '', locked: true),
                      _sectionGap(),

                      // ── Payment Mode ──────────────────────────────────
                      _label("Payment Mode"),
                      _buildDropdown<String>(
                        hint: "Select Mode",
                        value: selectedPaymentMode,
                        items: paymentModes
                            .map((m) => DropdownMenuItem<String>(
                          value: m,
                          child: Text(m),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() {
                          selectedPaymentMode = val;
                          if (val == 'Cash') {
                            _bankNameController.clear();
                            _branchCodeController.clear();
                            _beneficiaryAccountNumberController.clear();
                            _beneficiaryAccountNameController.clear();
                            _beneficiaryBankNameController.clear();
                          }
                        }),
                      ),
                      _sectionGap(),

                      // ── Bank Details (hidden for Cash) ─────────────────
                      if (_requiresBankDetails) ...[
                        _label("Bank Name"),
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            controller: _bankNameController,
                            decoration: _fieldDecoration("Bank Name"),
                          ),
                        ),
                        _sectionGap(),

                        _label("Branch Code"),
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            controller: _branchCodeController,
                            decoration: _fieldDecoration("Branch Code"),
                          ),
                        ),
                        _sectionGap(),

                        _label("Beneficiary Account Number"),
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            controller: _beneficiaryAccountNumberController,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration("Account Number"),
                          ),
                        ),
                        _sectionGap(),

                        _label("Beneficiary Account Name"),
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            controller: _beneficiaryAccountNameController,
                            decoration:
                            _fieldDecoration("Account Holder Name"),
                          ),
                        ),
                        _sectionGap(),

                        _label("Beneficiary Bank Name"),
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            controller: _beneficiaryBankNameController,
                            decoration:
                            _fieldDecoration("Beneficiary Bank Name"),
                          ),
                        ),
                        _sectionGap(),
                      ],

                      const SizedBox(height: 14),

                      // ── Cancel / Save ──────────────────────────────────
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
                              onPressed: _onSave,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor:
                                FrontendConfigs.kPrimaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: FrontendConfigs.kAppBorder,
                                ),
                              ),
                              child: const Text(
                                "Save",
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
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildReceiptImagePicker() {
    return Stack(
      children: [
        InkWell(
          onTap: () => showImagePickerBottomSheet(context),
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: FrontendConfigs.kAppBorder,
              color: FrontendConfigs.kTextFieldColor,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: receiptImage != null
                ? ClipRRect(
              borderRadius: FrontendConfigs.kAppBorder,
              child: Image.file(receiptImage!, fit: BoxFit.cover),
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
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  "JPG, PNG etc (max. 10MB)",
                  style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // Edit button — only shown once an image is selected
        if (receiptImage != null)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                // ── Crop ──────────────────────────────────────────────
                _imageActionButton(
                  icon: Icons.crop,
                  tooltip: 'Crop',
                  onTap: _cropImage,
                ),
                const SizedBox(width: 6),
                // ── Edit (brightness, contrast, filters, zoom …) ──────
                _imageActionButton(
                  icon: Icons.tune,
                  tooltip: 'Edit',
                  onTap: _editImage,
                ),
                const SizedBox(width: 6),
                // ── Remove ────────────────────────────────────────────
                _imageActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Remove',
                  onTap: () => setState(() => receiptImage = null),
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

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () => _showCupertinoDatePicker(context),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: FrontendConfigs.kAppBorder,
          color: FrontendConfigs.kTextFieldColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MM/dd/yyyy').format(selectedDate),
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w400),
            ),
            const Icon(CupertinoIcons.calendar, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onSave() {
    if (_distributorId == null) {
      getFlushBar(context, title: "Distributor not found. Please go back and try again.");
      return;
    }
    if (_amountController.text.isEmpty) {
      getFlushBar(context, title: "Please enter the amount.");
      return;
    }
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      getFlushBar(context, title: "Please enter a valid amount.");
      return;
    }
    if (_zoneId == null) {
      getFlushBar(context, title: "Zone not found for this distributor.");
      return;
    }
    if (_townId == null) {
      getFlushBar(context, title: "Town not found for this distributor.");
      return;
    }
    if (selectedPaymentMode == null) {
      getFlushBar(context, title: "Please select a payment mode.");
      return;
    }

    if (_requiresBankDetails) {
      if (_bankNameController.text.trim().isEmpty) {
        getFlushBar(context, title: "Please enter the bank name.");
        return;
      }
      if (_branchCodeController.text.trim().isEmpty) {
        getFlushBar(context, title: "Please enter the branch code.");
        return;
      }
      if (_beneficiaryAccountNumberController.text.trim().isEmpty) {
        getFlushBar(
            context, title: "Please enter beneficiary account number.");
        return;
      }
      if (_beneficiaryAccountNameController.text.trim().isEmpty) {
        getFlushBar(context, title: "Please enter beneficiary account name.");
        return;
      }
      if (_beneficiaryBankNameController.text.trim().isEmpty) {
        getFlushBar(context, title: "Please enter beneficiary bank name.");
        return;
      }
    }

    final userDetails = context.read<UserProvider>().getSalesUserDetails();
    final tsmId =
    (userDetails?.user?.id ?? userDetails?.user?.salesId ?? '').trim();
    if (tsmId.isEmpty) {
      getFlushBar(context,
          title: "Unable to identify user. Please log in again.");
      return;
    }

    final token = userDetails?.token;
    if (token == null || token.isEmpty) {
      getFlushBar(context, title: "Session expired. Please log in again.");
      return;
    }

    final model = AddRecoveryModel(
      distributionName: _distributorName!,
      zone: _zoneId!,
      town: _townId!,
      tsm: tsmId,
      recordedBy: tsmId,
      amount: amount,
      date: selectedDate.toIso8601String(),
      paymentMode: selectedPaymentMode!,
      bankName: _requiresBankDetails
          ? _bankNameController.text.trim()
          : 'null',
      branchCode: _requiresBankDetails
          ? _branchCodeController.text.trim()
          : 'null',
      beneficiaryAccountNumber: _requiresBankDetails
          ? _beneficiaryAccountNumberController.text.trim()
          : 'null',
      beneficiaryAccountName: _requiresBankDetails
          ? _beneficiaryAccountNameController.text.trim()
          : 'null',
      beneficiaryBankName: _requiresBankDetails
          ? _beneficiaryBankNameController.text.trim()
          : 'null',
      receiptPic: receiptImage?.path,
    );

    _retailerBloc.add(AddRecoveryEvent(model, token));
  }

  // ── Custom wheel date picker (no future dates) ───────────────────────────

  void _showCupertinoDatePicker(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DatePickerSheet(
        initialDate: selectedDate,
        title: 'Select Date',
      ),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // ── Image picking, cropping, editing ─────────────────────────────────────

  void showImagePickerBottomSheet(BuildContext context) {
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
              text: "Upload Receipt",
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
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _getReceiptImage(ImageSource.camera);
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
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _getReceiptImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Pick image from [source], then immediately open the pro editor.
  Future<void> _getReceiptImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(imageQuality: 85, source: source);
    if (pickedFile == null) return;
    final bytes = await File(pickedFile.path).readAsBytes();
    await _openProEditor(bytes);
  }

  /// Re-open the editor in crop-rotate mode for an already-selected image.
  Future<void> _cropImage() async {
    if (receiptImage == null) return;
    final bytes = await receiptImage!.readAsBytes();
    await _openProEditor(bytes, cropOnly: true);
  }

  /// Re-open the full editor (filters, tune, draw, text, emoji …).
  Future<void> _editImage() async {
    if (receiptImage == null) return;
    final bytes = await receiptImage!.readAsBytes();
    await _openProEditor(bytes);
  }

  /// Opens ProImageEditor and saves the result back to [receiptImage].
  /// Uses default ProImageEditorConfigs() for maximum version compatibility.
  Future<void> _openProEditor(Uint8List bytes, {bool cropOnly = false}) async {
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
          '${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(path).writeAsBytes(result!);
      setState(() => receiptImage = saved);
    }
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Custom Cupertino-wheel date picker bottom sheet
// • Prevents selecting any future date (today is the maximum)
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerSheet extends StatefulWidget {
  final DateTime? initialDate;
  final String title;
  const _DatePickerSheet({this.initialDate, this.title = 'Date'});

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late int _day;
  late int _month;
  late int _year;

  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _yearCtrl;

  final DateTime _now = DateTime.now();

  int _daysInMonth(int m, int y) {
    if (m == 2) return (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28;
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1];
  }

  /// Max selectable day: today's day if same year+month, else last day of month.
  int get _maxDays =>
      (_year == _now.year && _month == _now.month) ? _now.day : _daysInMonth(_month, _year);

  /// Max selectable month: current month if same year, else 12.
  int get _maxMonths => _year == _now.year ? _now.month : 12;

  @override
  void initState() {
    super.initState();
    // Clamp initialDate to today if it is in the future.
    final raw = widget.initialDate ?? DateTime.now();
    final d = raw.isAfter(_now) ? _now : raw;
    _day   = d.day;
    _month = d.month;
    _year  = d.year;
    _dayCtrl   = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl  = FixedExtentScrollController(initialItem: _year - 1900);
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _clampAndSync() {
    if (_month > _maxMonths) {
      _month = _maxMonths;
      _monthCtrl.jumpToItem(_month - 1);
    }
    if (_day > _maxDays) {
      _day = _maxDays;
      _dayCtrl.jumpToItem(_day - 1);
    }
  }

  // ── Style constants ──────────────────────────────────────────────────────

  static const _textColor     = Color(0xFF1A1A1A);
  static const _borderColor   = Color(0xFFD7D7D7);
  static const double _sheetRadius  = 20;
  static const double _itemExtent   = 44;
  static const double _pickerHeight = 200;
  static const double _btnRadius    = 10;
  static const double _btnPadV      = 14;

  TextStyle get _pickerTextStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: _textColor,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: _borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _day   = _now.day;
                      _month = _now.month;
                      _year  = _now.year;
                    });
                    _dayCtrl.jumpToItem(_now.day - 1);
                    _monthCtrl.jumpToItem(_now.month - 1);
                    _yearCtrl.jumpToItem(_now.year - 1900);
                  },
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pickers row
          SizedBox(
            height: _pickerHeight,
            child: Row(
              children: [
                // ── Day ───────────────────────────────────────────────
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _dayCtrl,
                    itemExtent: _itemExtent,
                    onSelectedItemChanged: (i) => setState(() => _day = i + 1),
                    children: List.generate(
                      _maxDays,
                          (i) => Center(
                        child: Text('${i + 1}', style: _pickerTextStyle),
                      ),
                    ),
                  ),
                ),

                // ── Month ─────────────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: CupertinoPicker(
                    scrollController: _monthCtrl,
                    itemExtent: _itemExtent,
                    onSelectedItemChanged: (i) {
                      setState(() {
                        _month = i + 1;
                        _clampAndSync();
                      });
                    },
                    children: List.generate(
                      _maxMonths,
                          (i) => Center(
                        child: Text(_months[i], style: _pickerTextStyle),
                      ),
                    ),
                  ),
                ),

                // ── Year ──────────────────────────────────────────────
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _yearCtrl,
                    itemExtent: _itemExtent,
                    onSelectedItemChanged: (i) {
                      setState(() {
                        _year = 1900 + i;
                        _clampAndSync();
                      });
                    },
                    // Years from 1900 up to and including today's year only.
                    children: List.generate(
                      _now.year - 1900 + 1,
                          (i) => Center(
                        child: Text('${1900 + i}', style: _pickerTextStyle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cancel / Confirm buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: FrontendConfigs.kPrimaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_btnRadius),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: _btnPadV),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FrontendConfigs.kPrimaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(DateTime(_year, _month, _day)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FrontendConfigs.kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_btnRadius),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: _btnPadV),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}