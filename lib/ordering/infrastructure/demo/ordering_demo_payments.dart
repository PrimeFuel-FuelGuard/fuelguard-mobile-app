part of 'ordering_demo_handler.dart';

/// Pagos y catálogo de pagos del contexto ordering en la demo (`/payments`).
extension OrderingDemoPayments on OrderingDemoHandler {
  DemoResponse? _paymentRoutes(DemoRequest r) {
    final company = r.match('GET', '/payments/company/:id');
    if (company != null) {
      return DemoResponse.json([
        for (final p in _payments)
          if (p.companyId == _idOf(company)) p.toJson(),
      ]);
    }
    final provider = r.match('GET', '/payments/provider/:id');
    if (provider != null) return _providerPayments(_idOf(provider), r.query);
    final forOrder = r.match('GET', '/payments/order/:id');
    if (forOrder != null) {
      final rows = [
        for (final p in _payments)
          if (p.orderId == _idOf(forOrder)) p,
      ];
      return rows.isEmpty
          ? _notFound('Pago')
          : DemoResponse.json(rows.last.toJson());
    }
    if (r.match('POST', '/payments') != null) return _createPayment(r.json);
    final complete = r.match('POST', '/payments/:id/complete');
    if (complete != null) {
      return _completePayment(_idOf(complete), r.json['transactionReference']);
    }
    final refund = r.match('POST', '/payments/:id/refund');
    if (refund != null) return _refundPayment(_idOf(refund));
    return null;
  }

  DemoResponse _providerPayments(int providerId, Map<String, String> query) {
    final status = query['status'];
    final from = DateTime.tryParse(query['from'] ?? '');
    final to = DateTime.tryParse(query['to'] ?? '');
    final rows = <Map<String, dynamic>>[];
    for (final p in _payments) {
      final order = _firstWhere(_orders, (o) => o.id == p.orderId);
      if (order == null || order.providerId != providerId) continue;
      if (status != null && status.isNotEmpty && p.status != status) continue;
      final created = _createdAt[p.id] ?? p.paidAt ?? '2026-11-01T00:00:00';
      final createdAt = DateTime.tryParse(created) ?? DateTime(2026, 11);
      if (from != null && createdAt.isBefore(from)) continue;
      if (to != null && createdAt.isAfter(to)) continue;
      rows.add(
        ProviderPayment(
          id: p.id,
          orderId: p.orderId,
          buyerCompanyId: p.companyId,
          buyerName: _buyerName(p.companyId),
          amount: p.amount,
          currency: null,
          status: p.status,
          paymentMethod: p.paymentMethod,
          createdAt: created,
          updatedAt: p.paidAt ?? created,
          paidAt: p.paidAt,
        ).toJson(),
      );
    }
    return DemoResponse.json(rows);
  }

  DemoResponse _createPayment(Map<String, dynamic> body) {
    final orderId = _intOf(body['orderId']);
    final companyId = _intOf(body['companyId']);
    final amount = (body['amount'] as num?)?.toDouble();
    final method = body['paymentMethod'];
    if (orderId == null ||
        companyId == null ||
        amount == null ||
        method is! String) {
      return DemoResponse.error(400, 'Pago inválido (demo)');
    }
    final order = _firstWhere(_orders, (o) => o.id == orderId);
    if (order == null) return _notFound('Orden');
    if (order.status != OrderStatus.pendingPayment ||
        order.companyId != companyId ||
        (amount - order.totalPrice).abs() > 0.005 ||
        _payments.any(
          (p) =>
              p.orderId == orderId &&
              (p.status == PaymentStatus.pending ||
                  p.status == PaymentStatus.completed),
        )) {
      return _conflict();
    }
    if (!PaymentMethod.values.contains(method)) {
      return DemoResponse.error(400, 'Método de pago inválido (demo)');
    }
    final payment = Payment(
      id: _nextId(_payments.map((p) => p.id), DemoWorld.paymentIdRange.$1),
      orderId: orderId,
      companyId: companyId,
      amount: amount,
      status: PaymentStatus.pending,
      paymentMethod: method,
      transactionReference: null,
      paidAt: null,
    );
    _payments.add(payment);
    _createdAt[payment.id] = DateTime.now().toIso8601String();
    return DemoResponse.json(payment.toJson());
  }

  DemoResponse _completePayment(int id, Object? reference) {
    final text = reference is String ? reference.trim() : '';
    if (text.isEmpty) {
      return DemoResponse.error(400, 'La referencia es obligatoria (demo)');
    }
    final index = _payments.indexWhere((p) => p.id == id);
    if (index < 0) return _notFound('Pago');
    final payment = _payments[index];
    if (payment.status != PaymentStatus.pending) return _conflict();
    final completed = payment.copyWith(
      status: PaymentStatus.completed,
      transactionReference: text,
      paidAt: DateTime.now().toIso8601String(),
    );
    _payments[index] = completed;
    final orderIndex = _orders.indexWhere((o) => o.id == payment.orderId);
    if (orderIndex >= 0 &&
        _orders[orderIndex].status == OrderStatus.pendingPayment) {
      _orders[orderIndex] = _orders[orderIndex].copyWith(
        status: OrderStatus.paid,
      );
    }
    return DemoResponse.json(completed.toJson());
  }

  DemoResponse _refundPayment(int id) {
    final index = _payments.indexWhere((p) => p.id == id);
    if (index < 0) return _notFound('Pago');
    final payment = _payments[index];
    if (payment.status != PaymentStatus.completed) {
      return DemoResponse(409, {
        'message': 'Solo se puede reembolsar un pago completado (demo)',
        'code': 'PAYMENT_CONFLICT',
      });
    }
    final refunded = payment.copyWith(status: PaymentStatus.refunded);
    _payments[index] = refunded;
    return DemoResponse.json(refunded.toJson());
  }

  String? _buyerName(int companyId) => switch (companyId) {
    DemoWorld.buyerCompanyId => DemoWorld.buyerCompanyName,
    DemoWorld.buyer2CompanyId => DemoWorld.buyer2CompanyName,
    _ => null,
  };
}
