import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bill_model.dart';
import '../services/notification_service.dart';
import '../services/remote_bill_service.dart';

class BillProvider extends ChangeNotifier {
  BillProvider({
    RemoteBillService? remoteBillService,
    NotificationService? notificationService,
  }) : _remoteBillService = remoteBillService ?? RemoteBillService(),
       _notificationService =
           notificationService ?? NotificationService.instance {
    loadBills();
  }

  final RemoteBillService _remoteBillService;
  final NotificationService _notificationService;
  final List<BillModel> _bills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BillModel> get bills => List.unmodifiable(_bills);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBills() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteBills = await _remoteBillService.fetchBills();
      _bills
        ..clear()
        ..addAll(remoteBills)
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      await _syncNotifications();
    } catch (error, stackTrace) {
      debugPrint('Load remote bills error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyError(error);
      _bills.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBill(BillModel bill) {
    return _runMutation(
      actionName: 'addBill',
      action: () async {
        await _remoteBillService.addBill(bill);
        await _reloadSilently();
      },
    );
  }

  Future<bool> updateBill(BillModel bill) {
    return _runMutation(
      actionName: 'updateBill',
      action: () async {
        await _remoteBillService.updateBill(bill);
        await _reloadSilently();
      },
    );
  }

  Future<bool> deleteBill(String id) {
    return _runMutation(
      actionName: 'deleteBill',
      action: () async {
        await _remoteBillService.deleteBill(id);
        await _notificationService.cancelBillReminder(id);
        _bills.removeWhere((bill) => bill.id == id);
      },
    );
  }

  Future<bool> markAsPaid(String id) {
    return _runMutation(
      actionName: 'markAsPaid',
      action: () async {
        await _remoteBillService.markBillAsPaid(id);
        await _notificationService.cancelBillReminder(id);
        await _reloadSilently();
      },
    );
  }

  Future<bool> markAsUnpaid(String id) {
    return _runMutation(
      actionName: 'markAsUnpaid',
      action: () async {
        await _remoteBillService.markBillAsUnpaid(id);
        await _reloadSilently();
      },
    );
  }

  List<BillModel> getUpcomingBills({int? limit}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming =
        _bills
            .where((bill) => !bill.isPaid && !bill.dueDate.isBefore(today))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (limit == null || upcoming.length <= limit) return upcoming;
    return upcoming.take(limit).toList();
  }

  List<BillModel> getOverdueBills() {
    return _bills.where((bill) => bill.isOverdue).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<BillModel> getBillsByMonth(int month, int year) {
    return _bills
        .where(
          (bill) => bill.dueDate.month == month && bill.dueDate.year == year,
        )
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  void clear() {
    _bills.clear();
    _errorMessage = null;
    _isLoading = false;
    unawaited(_notificationService.cancelAllBillReminders());
    notifyListeners();
  }

  Future<bool> _runMutation({
    required String actionName,
    required Future<void> Function() action,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Remote bill $actionName error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadSilently() async {
    final remoteBills = await _remoteBillService.fetchBills();
    _bills
      ..clear()
      ..addAll(remoteBills)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    await _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    await _notificationService.requestPermission();
    await _notificationService.cancelAllBillReminders();
    for (final bill in _bills) {
      if (bill.isPaid) {
        await _notificationService.cancelBillReminder(bill.id);
      } else {
        await _notificationService.scheduleBillReminder(bill);
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is StateError) return error.message;
    if (error is PostgrestException) {
      return 'Gagal memproses data tagihan. Silakan coba lagi.';
    }
    if (error is AuthException) {
      return 'Sesi login bermasalah. Silakan login ulang.';
    }

    final message = error.toString();
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('socket') ||
        lowerMessage.contains('network') ||
        lowerMessage.contains('failed host lookup')) {
      return 'Koneksi internet bermasalah. Coba lagi nanti.';
    }

    return message;
  }
}
