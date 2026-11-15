part of 'ordering_store.dart';

/// Pagos del comprador, detalle de orden con su pago y pagos del distribuidor.
extension OrderingStorePayments on OrderingStore {
  void loadPayments() {
    if (_loading || _refundingId != null) return;
    _update(() => _refundError = '');
    final companyId = _iam.companyId;
    if (!_iam.isBuyer || companyId == null) {
      _update(() {
        _payments = const [];
        _error = 'ordering.missing-organization';
      });
      return;
    }
    _run(
      () => _api.paymentsForCompany(companyId),
      (value) => _payments = value,
    );
  }

  void refundPayment(Payment payment) {
    final current = _find(_payments, (row) => row.id == payment.id);
    if (!_iam.isBuyer ||
        current == null ||
        current.status != PaymentStatus.completed ||
        current.companyId != _iam.companyId ||
        _refundingId != null ||
        _loading) {
      return;
    }
    _update(() {
      _refundingId = payment.id;
      _refundError = '';
      _notice = '';
    });
    _refund(payment.id);
  }

  Future<void> _refund(int id) async {
    try {
      final updated = await _api.refundPayment(id);
      _update(() {
        _payments = [
          for (final row in _payments) row.id == updated.id ? updated : row,
        ];
        _notice = 'payment-history.refund-success';
      });
    } catch (error) {
      _update(() => _refundError = _failure(error, 'errors.generic'));
    } finally {
      _update(() => _refundingId = null);
    }
  }

  /// Abre el detalle de una orden: descarta el contexto de pago de la anterior y la carga.
  void openOrder(int id) {
    _update(_resetOrderContext);
    loadOrder(id);
  }

  /// Reintenta leer el pago de la orden abierta.
  void retryPayment() {
    final current = order;
    if (current == null || _loading || _paying || _paymentLoading) return;
    _update(() => _paymentOrderLoaded = null);
    loadOrder(current.id);
  }

  /// Registra el pago de la orden abierta (comprador, estado `PENDING_PAYMENT`).
  void payOrder(Order target, String paymentMethod) {
    final companyId = _iam.companyId;
    if (!_iam.isBuyer ||
        companyId == null ||
        target.companyId != companyId ||
        !_orders.any((row) => row.id == target.id) ||
        target.status != OrderStatus.pendingPayment ||
        _loading ||
        _paying ||
        _paymentLoading ||
        _payment != null ||
        _paymentReadError ||
        !target.totalPrice.isFinite ||
        target.totalPrice <= 0 ||
        !PaymentMethod.values.contains(paymentMethod)) {
      return;
    }
    _update(() {
      _paying = true;
      _paymentError = '';
    });
    _api
        .createPayment(target.id, companyId, target.totalPrice, paymentMethod)
        .then(
          (created) => _update(() {
            _payment = created;
            _paying = false;
          }),
          onError: (Object error) => _update(() {
            _paymentReadError = true;
            _paymentError = _statusKey(error, 'order-detail.payment-error');
            _paying = false;
          }),
        );
  }

  /// Confirma el pago pendiente de la orden con la referencia de la transacción.
  void completePayment(int orderId, String transactionReference) {
    final payment = _payment;
    final current = order;
    final reference = transactionReference.trim();
    if (!_iam.isBuyer ||
        payment == null ||
        current == null ||
        current.id != orderId ||
        payment.orderId != orderId ||
        payment.companyId != _iam.companyId ||
        current.companyId != _iam.companyId ||
        current.status != OrderStatus.pendingPayment ||
        payment.status != PaymentStatus.pending ||
        _loading ||
        _paymentLoading ||
        _paying ||
        reference.isEmpty) {
      return;
    }
    _update(() {
      _paying = true;
      _paymentError = '';
    });
    _api.completePayment(payment.id, reference).then(
      (completed) {
        _update(() {
          _payment = completed;
          _paying = false;
        });
        loadOrder(orderId);
      },
      onError: (Object error) => _update(() {
        _paymentError = _statusKey(error, 'order-detail.payment-error');
        _paying = false;
      }),
    );
  }

  void loadProviderPayments({String status = ''}) {
    _providerStatus = status;
    final providerId = _iam.providerId;
    if (providerId == null) {
      _update(() {
        _providerPayments = const [];
        _error = 'errors.http-403';
      });
      return;
    }
    _run(
      () => _api.providerPayments(
        providerId,
        status: status.isEmpty ? null : status,
      ),
      (rows) => _providerPayments = rows,
      keepNotice: true,
    );
  }

  void completeProviderPayment(ProviderPayment target, String reference) {
    final text = reference.trim();
    if (target.status != PaymentStatus.pending ||
        _busyProviderPaymentId != null ||
        text.isEmpty) {
      return;
    }
    _runProviderAction(
      target,
      () => _api.completePayment(target.id, text),
      'provider-payments.complete-success',
    );
  }

  void refundProviderPayment(ProviderPayment target) {
    if (target.status != PaymentStatus.completed ||
        _busyProviderPaymentId != null) {
      return;
    }
    _runProviderAction(
      target,
      () => _api.refundProviderPayment(target.id),
      'provider-payments.refund-success',
      refund: true,
    );
  }

  Future<void> _runProviderAction<T>(
    ProviderPayment target,
    Future<T> Function() operation,
    String success, {
    bool refund = false,
  }) async {
    _update(() {
      _busyProviderPaymentId = target.id;
      _providerActionError = '';
      _notice = '';
    });
    try {
      await operation();
      _notice = success;
      loadProviderPayments(status: _providerStatus);
    } catch (error) {
      _providerActionError =
          refund && error is ApiException && error.code == 'PAYMENT_CONFLICT'
          ? 'provider-payments.refund-conflict'
          : _statusKey(error, 'provider-payments.action-error');
    } finally {
      _update(() => _busyProviderPaymentId = null);
    }
  }

  void _loadCompanyNameFor(Order loaded) {
    if (!_iam.isBuyer || _companyName != null) return;
    _quietly(() => _api.buyerCompany(loaded.companyId), (company) {
      if (order?.companyId == loaded.companyId) _companyName = company.name;
    });
  }

  void _loadPaymentFor(Order loaded) {
    if (!_paymentOrderStatuses.contains(loaded.status) ||
        _paymentOrderLoaded == loaded.id) {
      return;
    }
    _update(() {
      _paymentOrderLoaded = loaded.id;
      _paymentLoading = true;
      _paymentReadError = false;
      _paymentError = '';
    });
    _api
        .paymentForOrder(loaded.id)
        .then(
          (value) => _update(() {
            if (_paymentOrderLoaded != loaded.id) return;
            _payment = value;
            _paymentLoading = false;
          }),
          onError: (Object error) => _update(() {
            if (_paymentOrderLoaded != loaded.id) return;
            _payment = null;
            _paymentLoading = false;
            if (error is ApiException && error.status == 404) return;
            _paymentReadError = true;
            _paymentError = _statusKey(error, 'order-detail.payment-error');
          }),
        );
  }

  void _resetOrderContext() {
    _companyName = null;
    _payment = null;
    _paymentOrderLoaded = null;
    _paymentLoading = false;
    _paymentReadError = false;
    _paying = false;
    _paymentError = '';
  }
}
