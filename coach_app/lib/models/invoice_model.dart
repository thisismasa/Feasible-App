class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String trainerId;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final InvoiceStatus status;
  final DateTime? paidDate;
  final String? paymentMethod;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.trainerId,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.paidDate,
    this.paymentMethod,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      trainerId: map['trainerId'] ?? '',
      issueDate: DateTime.parse(map['issueDate']),
      dueDate: DateTime.parse(map['dueDate']),
      items: (map['items'] as List<dynamic>)
          .map((item) => InvoiceItem.fromMap(item))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString() == 'InvoiceStatus.${map['status']}',
        orElse: () => InvoiceStatus.pending,
      ),
      paidDate:
          map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
      paymentMethod: map['paymentMethod'],
    );
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? json['invoiceNumber'] ?? '',
      clientId: json['client_id'] ?? json['clientId'] ?? '',
      clientName: json['client_name'] ?? json['clientName'] ?? '',
      clientEmail: json['client_email'] ?? json['clientEmail'] ?? '',
      trainerId: json['trainer_id'] ?? json['trainerId'] ?? '',
      issueDate: json['issue_date'] != null
          ? DateTime.parse(json['issue_date'])
          : json['issueDate'] != null
              ? DateTime.parse(json['issueDate'])
              : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : json['dueDate'] != null
              ? DateTime.parse(json['dueDate'])
              : DateTime.now().add(const Duration(days: 30)),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ?? [],
      subtotal: ((json['subtotal'] ?? 0) is int
          ? (json['subtotal'] as int).toDouble()
          : json['subtotal'] ?? 0.0) as double,
      tax: ((json['tax'] ?? 0) is int
          ? (json['tax'] as int).toDouble()
          : json['tax'] ?? 0.0) as double,
      total: ((json['total'] ?? 0) is int
          ? (json['total'] as int).toDouble()
          : json['total'] ?? 0.0) as double,
      status: json['status'] is String
          ? InvoiceStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => InvoiceStatus.pending,
            )
          : InvoiceStatus.pending,
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'])
          : json['paidDate'] != null
              ? DateTime.parse(json['paidDate'])
              : null,
      paymentMethod: json['payment_method'] ?? json['paymentMethod'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'trainerId': trainerId,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status.name,
      'paidDate': paidDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
  }
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

enum InvoiceStatus {
  pending,
  paid,
  overdue,
  cancelled,
}
