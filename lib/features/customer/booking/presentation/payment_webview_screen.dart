import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_colors.dart';

class PaymentWebViewArgs {
  final String redirectUrl;
  final String title;

  const PaymentWebViewArgs({required this.redirectUrl, required this.title});
}

class PaymentWebViewScreen extends StatefulWidget {
  final PaymentWebViewArgs args;

  const PaymentWebViewScreen({super.key, required this.args});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;

            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;

            setState(() {
              _isLoading = false;
            });

            final lowerUrl = url.toLowerCase();

            if (lowerUrl.contains('finish') ||
                lowerUrl.contains('settlement') ||
                lowerUrl.contains('transaction_status=capture')) {
              Navigator.pop(context, true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.args.redirectUrl));
  }

  void _finishManually() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(widget.args.title),
        actions: [
          TextButton(
            onPressed: _finishManually,
            child: const Text(
              'Selesai',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.white,
            ),
        ],
      ),
    );
  }
}
