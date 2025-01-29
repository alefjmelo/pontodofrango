// ignore_for_file: file_names

import 'package:flutter/material.dart';

void showCustomOverlay(BuildContext context, String message) {
  OverlayState overlayState = Overlay.of(context);
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          height: 40,
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.8),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Center(
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    ),
  );

  // Insert the overlay entry into the overlay
  overlayState.insert(overlayEntry);

  // Remove the overlay entry after 3 seconds
  Future.delayed(Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}
