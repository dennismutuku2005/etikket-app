import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/feedback_util.dart';
import '../../core/utils/qr_code_parser.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/usecases/lookup_ticket_usecase.dart';
import '../../domain/usecases/verify_ticket_usecase.dart';

class ScannerController extends ChangeNotifier {
  final LookupTicketUseCase lookupTicketUseCase;
  final VerifyTicketUseCase verifyTicketUseCase;

  MobileScannerController? _mobileScannerController;
  MobileScannerController? get mobileScannerController => _mobileScannerController;

  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  bool _isScanningActive = false;
  bool _isHomeScreen = true;
  bool _isLookingUp = false;
  bool _isVerifying = false;
  bool _hasCameraPermission = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  TicketEntity? _selectedTicket;
  String _statusMessage = 'Point camera at ticket QR code to scan.';
  String? _errorMessage;
  int _scannedCount = 0;
  final List<TicketEntity> _recentScans = [];

  ScannerController({
    required this.lookupTicketUseCase,
    required this.verifyTicketUseCase,
  }) {
    _initScannerController();
  }

  void _initScannerController() {
    _mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  bool get isTorchOn => _isTorchOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get isScanningActive => _isScanningActive;
  bool get isHomeScreen => _isHomeScreen;
  bool get isLookingUp => _isLookingUp;
  bool get isVerifying => _isVerifying;
  bool get hasCameraPermission => _hasCameraPermission;
  TicketEntity? get selectedTicket => _selectedTicket;
  String get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  int get scannedCount => _scannedCount;
  List<TicketEntity> get recentScans => List.unmodifiable(_recentScans);

  Future<void> checkAndRequestCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        _hasCameraPermission = true;
      } else {
        final requested = await Permission.camera.request();
        _hasCameraPermission = requested.isGranted;
      }
      if (!_hasCameraPermission) {
        _errorMessage = 'Camera access is required to scan tickets. You can still use manual lookup.';
        _statusMessage = 'Camera permission required';
      } else {
        _errorMessage = null;
        _statusMessage = 'Point camera at ticket QR code to scan.';
      }
    } catch (_) {
      _hasCameraPermission = false;
      _errorMessage = 'Camera is unavailable on this device. Please use manual lookup instead.';
      _statusMessage = 'Camera unavailable';
    }
    notifyListeners();
  }

  void setScanningActive(bool active) {
    _isScanningActive = active;
    if (!active) {
      _mobileScannerController?.stop();
    } else if (!_isHomeScreen) {
      _mobileScannerController?.start();
    }
    notifyListeners();
  }

  void openHome() {
    _isHomeScreen = true;
    _isScanningActive = false;
    _errorMessage = null;
    _statusMessage = 'Ready to scan tickets';
    try {
      _mobileScannerController?.stop();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> startScanning({bool requestPermission = true}) async {
    _isHomeScreen = false;
    _isScanningActive = true;
    _statusMessage = 'Point camera at ticket QR code to scan.';
    if (requestPermission) {
      await checkAndRequestCameraPermission();
    }
    try {
      await _mobileScannerController?.start();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> pauseScanning() async {
    _isScanningActive = false;
    try {
      await _mobileScannerController?.stop();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> resumeScanning() async {
    if (!_isHomeScreen) {
      _isScanningActive = true;
      try {
        await _mobileScannerController?.start();
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> toggleTorch() async {
    if (_mobileScannerController != null) {
      try {
        await _mobileScannerController!.toggleTorch();
        _isTorchOn = !_isTorchOn;
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> switchCamera() async {
    if (_mobileScannerController != null) {
      try {
        await _mobileScannerController!.switchCamera();
        _isFrontCamera = !_isFrontCamera;
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<TicketEntity?> onBarcodeDetected(
    BarcodeCapture capture, {
    String? token,
  }) async {
    try {
      if (!_isScanningActive || _isLookingUp || _isVerifying) {
        return null;
      }

      final barcodes = capture.barcodes;
      if (barcodes.isEmpty) return null;

      final rawValue = barcodes.first.rawValue;
      if (rawValue == null || rawValue.trim().isEmpty) return null;

      final cleanCode = QrCodeParser.extractTicketCode(rawValue);
      if (cleanCode == null || cleanCode.isEmpty) return null;

      final now = DateTime.now();
      if (_lastScannedCode == cleanCode &&
          _lastScanTime != null &&
          now.difference(_lastScanTime!).inMilliseconds < 2500) {
        return null;
      }

      _lastScannedCode = cleanCode;
      _lastScanTime = now;

      await FeedbackUtil.successScan();
      return await lookupCode(cleanCode, token: token);
    } catch (_) {
      _errorMessage = 'The QR scan failed. Please try again or use manual lookup.';
      _statusMessage = 'Scan failed';
      _isScanningActive = true;
      notifyListeners();
      return null;
    }
  }

  Future<TicketEntity?> lookupCode(String rawCode, {String? token}) async {
    final cleanCode = QrCodeParser.extractTicketCode(rawCode);
    if (cleanCode == null || cleanCode.trim().isEmpty) {
      _errorMessage = 'Please enter or scan a valid ticket code.';
      _statusMessage = 'Invalid ticket code.';
      notifyListeners();
      return null;
    }

    _isLookingUp = true;
    _isScanningActive = false;
    _errorMessage = null;
    _statusMessage = 'Looking up ticket $cleanCode...';
    notifyListeners();

    try {
      final ticket = await lookupTicketUseCase(code: cleanCode, token: token);
      _selectedTicket = ticket;
      _isLookingUp = false;
      _errorMessage = null;
      _statusMessage = ticket.isCheckedIn
          ? 'Ticket ALREADY USED / Checked In.'
          : 'Found ticket for ${ticket.attendeeName}.';
      notifyListeners();
      return ticket;
    } on ServerException catch (e) {
      _selectedTicket = null;
      _isLookingUp = false;
      _errorMessage = e.message;
      _statusMessage = e.message;
      await FeedbackUtil.errorAlert();
      notifyListeners();
      return null;
    } on NetworkException catch (e) {
      _selectedTicket = null;
      _isLookingUp = false;
      _errorMessage = e.message;
      _statusMessage = e.message;
      await FeedbackUtil.errorAlert();
      notifyListeners();
      return null;
    } catch (_) {
      _selectedTicket = null;
      _isLookingUp = false;
      _errorMessage = 'Ticket lookup failed. Please try again or enter the code manually.';
      _statusMessage = 'Ticket lookup failed.';
      _isScanningActive = true;
      await FeedbackUtil.errorAlert();
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyCurrentTicket({
    required int staffId,
    required String staffName,
    String? token,
  }) async {
    if (_selectedTicket == null) return false;

    _isVerifying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await verifyTicketUseCase(
        code: _selectedTicket!.code,
        staffId: staffId,
        token: token,
      );

      final updated = _selectedTicket!.copyWith(
        status: 'checked_in',
        scannedBy: staffName,
        scannedAt: DateTime.now().toIso8601String(),
      );

      _selectedTicket = updated;
      _scannedCount++;
      _recentScans.insert(0, updated);
      _isVerifying = false;
      _statusMessage = 'Checked in ${updated.attendeeName} successfully!';
      await FeedbackUtil.mediumImpact();
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _isVerifying = false;
      _errorMessage = e.message;
      await FeedbackUtil.errorAlert();
      notifyListeners();
      return false;
    } catch (_) {
      _isVerifying = false;
      _errorMessage = 'Verification failed. Please try again.';
      _isScanningActive = true;
      await FeedbackUtil.errorAlert();
      notifyListeners();
      return false;
    }
  }

  void resetSelectedTicket() {
    _selectedTicket = null;
    _errorMessage = null;
    _statusMessage = 'Ready to scan tickets';
    _isScanningActive = false;
    _isHomeScreen = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _mobileScannerController?.dispose();
    super.dispose();
  }
}
