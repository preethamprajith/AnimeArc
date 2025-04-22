import 'package:flutter/material.dart';

class OrderStatus {
  static const int PROCESSING = 0;
  static const int CONFIRMED = 1;
  static const int SHIPPED = 2;
  static const int DELIVERED = 3;
  static const int CANCELLED = 4;

  static String getText(int status) {
    switch (status) {
      case CONFIRMED:
        return "Confirmed";
      case SHIPPED:
        return "Shipped";
      case DELIVERED:
        return "Delivered";
      case CANCELLED:
        return "Cancelled";
      default:
        return "Processing";
    }
  }

  static Color getColor(int status) {
    switch (status) {
      case CONFIRMED:
        return const Color(0xFF3498DB); // Blue
      case SHIPPED:
        return const Color(0xFFE67E22); // Orange
      case DELIVERED:
        return const Color(0xFF2ECC71); // Green
      case CANCELLED:
        return const Color(0xFFE74C3C); // Red
      default:
        return const Color(0xFF95A5A6); // Grey
    }
  }

  static IconData getIcon(int status) {
    switch (status) {
      case CONFIRMED:
        return Icons.check_circle_outline;
      case SHIPPED:
        return Icons.local_shipping_outlined;
      case DELIVERED:
        return Icons.done_all;
      case CANCELLED:
        return Icons.cancel_outlined;
      default:
        return Icons.pending_outlined;
    }
  }
}