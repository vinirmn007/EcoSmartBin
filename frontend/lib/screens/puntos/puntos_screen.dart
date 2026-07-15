import 'package:flutter/material.dart';
import '../../services/api_service.dart';

part 'puntos_view.dart';

class PuntosScreen extends StatefulWidget {
  const PuntosScreen({Key? key}) : super(key: key);

  @override
  State<PuntosScreen> createState() => _PuntosScreenState();
}

class _PuntosScreenState extends State<PuntosScreen> {
  Map<String, dynamic>? _balance;
  bool _loadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => _loadingBalance = true);
    final result = await ApiService.getBalance();
    if (mounted) {
      setState(() {
        _loadingBalance = false;
        if (result['success'] == true) _balance = result['data'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PuntosView(state: this);
  }
}
