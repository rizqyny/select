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
  int _progress = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;

            setState(() {
              _progress = progress;
            });
          },
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

            final isFinished =
                lowerUrl.contains('finish') ||
                lowerUrl.contains('success') ||
                lowerUrl.contains('settlement') ||
                lowerUrl.contains('capture') ||
                lowerUrl.contains('transaction_status=settlement') ||
                lowerUrl.contains('transaction_status=capture');

            if (isFinished) {
              Navigator.pop(context, true);
            }
          },
          onWebResourceError: (error) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gagal memuat halaman pembayaran: ${error.description}',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.args.redirectUrl));
  }

  void _finishManually() {
    Navigator.pop(context, true);
  }

  Future<void> _reload() async {
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final showProgress = _isLoading || _progress < 100;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(widget.args.title),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
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
          if (showProgress)
            LinearProgressIndicator(
              value: _progress == 0 ? null : _progress / 100,
              color: AppColors.primary,
              backgroundColor: AppColors.white,
            ),
        ],
      ),
    );
  }
}
