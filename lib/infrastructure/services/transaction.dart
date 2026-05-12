import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/transaction.dart';

class TransactionServices {
  ///Create Transaction
  Future<void> createTransaction(BuildContext context,
      {required TransactionModel model}) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('transactionCollection')
        .doc(model.orderID);
    await docRef.set(model.toJson(model.orderID.toString()));
  }

  ///Fetch Transaction
  Stream<List<TransactionModel>> streamTransaction(String salesPersonID) {
    return FirebaseFirestore.instance
        .collection('transactionCollection')
        .where('salesPersonID', isEqualTo: salesPersonID)
        .snapshots()
        .map((event) => event.docs
            .map((e) => TransactionModel.fromJson(e.data()))
            .toList());
  }

  ///Delete Transaction
  Future deleteTransaction(String docID) async {
    await FirebaseFirestore.instance
        .collection('transactionCollection')
        .doc(docID)
        .delete();
  }
}
