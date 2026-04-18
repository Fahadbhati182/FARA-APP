import 'package:flutter/material.dart';
import 'worker_orders_screen.dart';
import 'worker_request_screen.dart';
import '../owner/owner_record_external_order_screen.dart';
import '../../constants/colors.dart';

class WorkerMainNavigation extends StatefulWidget {
  const WorkerMainNavigation({super.key});

  @override
  State<WorkerMainNavigation> createState() => _WorkerMainNavigationState();
}

class _WorkerMainNavigationState extends State<WorkerMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WorkerOrdersScreen(),
    OwnerRecordExternalOrderScreen(),
    WorkerRequestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 0,
          // Larger font for workers
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          iconSize: 28,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.receipt_long_rounded),
              ),
              label: "My Orders",
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.add_to_photos_rounded),
              ),
              label: "Record Order",
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.add_shopping_cart_rounded),
              ),
              label: "Request Materials",
            ),
          ],
        ),
      ),
    );
  }
}