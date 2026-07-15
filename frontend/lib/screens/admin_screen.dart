import 'package:flutter/material.dart';

part 'admin_view.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Aquí podemos agregar el estado para listar basureros, etc.
  
  @override
  void initState() {
    super.initState();
    // fetchBasureros();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminView(state: this);
  }
}
