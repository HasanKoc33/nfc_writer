import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingWidget extends StatelessWidget {
  /// Loading widget with frosted glass background, progress bar and shimmer effect
  const LoadingWidget({
    Key? key,
    this.message = 'Yükleniyor...',
    this.progress,
    this.shimmerBaseColor = Colors.white54,
    this.shimmerHighlightColor = Colors.white,
  }) : super(key: key);

  /// Message to display below the progress indicator
  final String message;

  /// Progress value between 0.0 and 1.0
  /// If null, an indeterminate progress indicator will be shown
  final double? progress;

  /// Base color for shimmer effect
  final Color shimmerBaseColor;

  /// Highlight color for shimmer effect
  final Color shimmerHighlightColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Frosted glass background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.black.withOpacity(0.2),
          ),
        ),
        
        // Content
        Center(
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator with shimmer effect
                Shimmer.fromColors(
                  baseColor: shimmerBaseColor,
                  highlightColor: shimmerHighlightColor,
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.nfc,
                        size: 50,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Progress bar
                if (progress != null)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress! * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                
                // Message with shimmer effect
                Shimmer.fromColors(
                  baseColor: shimmerBaseColor,
                  highlightColor: shimmerHighlightColor,
                  period: const Duration(milliseconds: 1500),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A fullscreen loading widget that can be shown as an overlay
class FullscreenLoadingWidget extends StatelessWidget {
  /// Creates a fullscreen loading widget
  const FullscreenLoadingWidget({
    Key? key,
    this.message = 'Yükleniyor...',
    this.progress,
  }) : super(key: key);

  /// Message to display below the progress indicator
  final String message;

  /// Progress value between 0.0 and 1.0
  final double? progress;

  /// Shows a fullscreen loading widget
  static Future<void> show(
    BuildContext context, {
    String message = 'Yükleniyor...',
    double? progress,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FullscreenLoadingWidget(
        message: message,
        progress: progress,
      ),
    );
  }

  /// Hides the fullscreen loading widget
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: LoadingWidget(
          message: message,
          progress: progress,
        ),
      ),
    );
  }
}
