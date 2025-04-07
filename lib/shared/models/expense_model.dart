import 'package:uuid/uuid.dart';

class ExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String category;
  final String payerId;
  final String payerName;
  final DateTime date;
  final Map<String, double> splits;

  ExpenseModel({
    String? id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.category,
    required this.payerId,
    required this.payerName,
    DateTime? date,
    required this.splits,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'category': category,
      'payerId': payerId,
      'date': date.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      payerId: map['payerId'] as String,
      payerName: map['payerName'] as String,
      date: DateTime.parse(map['date'] as String),
      splits: Map<String, double>.from(map['splits'] as Map),
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? category,
    String? payerId,
    String? payerName,
    DateTime? date,
    Map<String, double>? splits,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      payerId: payerId ?? this.payerId,
      payerName: payerName ?? this.payerName,
      date: date ?? this.date,
      splits: splits ?? this.splits,
    );
  }
} 