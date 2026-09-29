import 'package:flutter/material.dart';

import '../models/medicine_model.dart';
import 'medicine_form_page.dart';

class EditMedicinePage extends StatelessWidget {
  final Medicine medicine;

  const EditMedicinePage({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) => MedicineFormPage(medicine: medicine);
}
