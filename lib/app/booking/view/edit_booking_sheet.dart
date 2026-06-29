import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/booking/model/booking_detail_model.dart';
import 'package:seedsuser/app/home/map_search_screen.dart';

/// Bottom sheet to edit a Pending booking's details (No. of Pieces, Salinity,
/// Packing Date, Delivery Date). Only reachable while the booking is Pending —
/// the backend also enforces that, so a confirmed booking can't be changed.
/// Returns `true` when the booking was saved, so the caller can refresh.
Future<bool?> showEditBookingSheet(
  BuildContext context, {
  required BookingDetailModel data,
  required MyBookingController controller,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditBookingSheet(data: data, controller: controller),
  );
}

class _EditBookingSheet extends StatefulWidget {
  final BookingDetailModel data;
  final MyBookingController controller;

  const _EditBookingSheet({required this.data, required this.controller});

  @override
  State<_EditBookingSheet> createState() => _EditBookingSheetState();
}

class _EditBookingSheetState extends State<_EditBookingSheet> {
  late final TextEditingController _piecesController;
  late String _salinity;
  DateTime? _packingDate;
  DateTime? _deliveryDate;

  late String _dropAddress;
  double? _dropLat; // set only when the user re-picks on the map
  double? _dropLng;
  bool _openingMap = false;

  static final List<String> _salinityOptions =
      List.generate(41, (i) => '$i'); // 0..40 PPT

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _piecesController = TextEditingController(text: d.pieces);
    _salinity = _salinityOptions.contains(d.salinity.toString())
        ? d.salinity.toString()
        : '0';
    _packingDate = _parseDate(d.preferredDate);
    _deliveryDate = _parseDate(d.deliveryDate.isNotEmpty ? d.deliveryDate : d.bookingDateTime);
    _dropAddress = d.droppingLocation;
  }

  /// Open the same map/search picker the booking form uses, centered on the
  /// user's current location, and update the drop address + coordinates.
  Future<void> _pickDropLocation() async {
    if (_openingMap) return;
    setState(() => _openingMap = true);

    double centerLat = 20.5937; // India centroid fallback
    double centerLng = 78.9629;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        centerLat = pos.latitude;
        centerLng = pos.longitude;
      }
    } catch (_) {
      // fall back to the default centre — the picker has search anyway.
    }

    if (!mounted) return;
    setState(() => _openingMap = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoogleMapSearchPlacesScreen(
          latitude: centerLat,
          longitude: centerLng,
          ontapSelectLocation: (location, fullAddress) {
            if (mounted) {
              setState(() {
                _dropAddress = fullAddress;
                _dropLat = location.latitude;
                _dropLng = location.longitude;
              });
            }
          },
        ),
      ),
    );
  }

  /// Parse the date string the API returns. The booking detail API formats
  /// dates as `d-m-Y` (e.g. 19-06-2026), which DateTime.tryParse can't read —
  /// so handle that (and d/m/Y) explicitly, falling back to ISO parsing.
  DateTime? _parseDate(String raw) {
    var s = raw.trim();
    if (s.isEmpty || s == '-') return null;

    // d-m-Y or d/m/Y (the format the detail API sends).
    final normalized = s.replaceAll('/', '-').replaceAll('.', '-');
    final m = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(normalized);
    if (m != null) {
      final day = int.tryParse(m.group(1)!);
      final month = int.tryParse(m.group(2)!);
      final year = int.tryParse(m.group(3)!);
      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    // ISO (yyyy-MM-dd / full timestamp) fallback.
    return DateTime.tryParse(s);
  }

  @override
  void dispose() {
    _piecesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isPacking) async {
    final initial = (isPacking ? _packingDate : _deliveryDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPacking) {
          _packingDate = picked;
        } else {
          _deliveryDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final pieces = _piecesController.text.trim();
    if (pieces.isEmpty || (int.tryParse(pieces) ?? 0) <= 0) {
      Get.snackbar('Invalid', 'Enter a valid number of pieces',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final ok = await widget.controller.updateBooking(
      bookingId: widget.data.bookingId.toString(),
      noOfPieces: pieces,
      salinity: _salinity,
      packingDate:
          _packingDate != null ? DateFormat('yyyy-MM-dd').format(_packingDate!) : null,
      deliveryDate:
          _deliveryDate != null ? DateFormat('yyyy-MM-dd').format(_deliveryDate!) : null,
      droppingLocation: _dropAddress,
      dropLat: _dropLat,
      dropLng: _dropLng,
    );

    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Edit Booking',
                  style: GoogleFonts.roboto(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '#${widget.data.bookingId}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'You can edit details while the booking is pending.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            const SizedBox(height: 20),

            _label('No. of Pieces'),
            const SizedBox(height: 6),
            TextField(
              controller: _piecesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _fieldDecoration('Enter number of pieces'),
            ),
            const SizedBox(height: 16),

            _label('Salinity (PPT)'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _salinity,
              isExpanded: true,
              decoration: _fieldDecoration('Select salinity'),
              items: _salinityOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s PPT')))
                  .toList(),
              onChanged: (v) => setState(() => _salinity = v ?? _salinity),
            ),
            const SizedBox(height: 16),

            _label('Packing Date'),
            const SizedBox(height: 6),
            _dateField(_packingDate, () => _pickDate(true)),
            const SizedBox(height: 16),

            _label('Delivery Date'),
            const SizedBox(height: 6),
            _dateField(_deliveryDate, () => _pickDate(false)),
            const SizedBox(height: 16),

            _label('Drop Location'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDropLocation,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _fieldDecoration('Select drop location'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dropAddress.trim().isNotEmpty
                            ? _dropAddress
                            : 'Select drop location',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _dropAddress.trim().isNotEmpty
                              ? Colors.black87
                              : Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _openingMap
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.location_on,
                            size: 20, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(
                () => ElevatedButton(
                  onPressed:
                      widget.controller.isCreateLoading.value ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: widget.controller.isCreateLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.roboto(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.roboto(fontSize: 13.5, fontWeight: FontWeight.w600),
      );

  Widget _dateField(DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _fieldDecoration('Select date'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Select date',
                style: TextStyle(
                  color: date != null ? Colors.black87 : Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.3),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
