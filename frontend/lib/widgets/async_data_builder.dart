import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AsyncDataBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final T? initialData;
  final Duration? timeout;

  const AsyncDataBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.initialData,
    this.timeout,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snapshot) {
        // Handle connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          debugPrint('🚨 AsyncDataBuilder Error: $error');

          return errorBuilder?.call(context, error) ??
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.somethingWentWrong,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.pleaseTryAgainLater,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Trigger rebuild by calling setState in parent
                            if (context.mounted) {
                              (context as Element).markNeedsBuild();
                            }
                          },
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                },
              );
        }

        // Handle data
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        // Fallback
        return Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Center(child: Text(l10n.noDataAvailable));
          },
        );
      },
    );
  }
}

class AsyncDataBuilderWithRefresh<T> extends StatefulWidget {
  final Future<T> Function() futureBuilder;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final T? initialData;
  final Duration? timeout;

  const AsyncDataBuilderWithRefresh({
    super.key,
    required this.futureBuilder,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.initialData,
    this.timeout,
  });

  @override
  State<AsyncDataBuilderWithRefresh<T>> createState() =>
      _AsyncDataBuilderWithRefreshState<T>();
}

class _AsyncDataBuilderWithRefreshState<T>
    extends State<AsyncDataBuilderWithRefresh<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.futureBuilder();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.futureBuilder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: AsyncDataBuilder<T>(
        future: _future,
        builder: widget.builder,
        errorBuilder: widget.errorBuilder,
        loadingBuilder: widget.loadingBuilder,
        initialData: widget.initialData,
        timeout: widget.timeout,
      ),
    );
  }
}
