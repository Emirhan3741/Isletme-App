import 'package:flutter/material.dart';
import '../controllers/base_list_controller.dart';
import 'common_state_widgets.dart';

class PaginatedListView<T> extends StatefulWidget {
  final BaseListController<T> controller;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? header;
  final EdgeInsets? padding;
  final double? itemSpacing;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final Color? color;
  final bool enablePullToRefresh;
  final ScrollPhysics? physics;

  const PaginatedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.header,
    this.padding,
    this.itemSpacing,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.color,
    this.enablePullToRefresh = true,
    this.physics,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data if not loaded
    if (widget.controller.items.isEmpty && !widget.controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadInitial();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return CommonLoadingWidget(
            message: 'Veriler yükleniyor...',
            color: widget.color,
          );
        }

        if (widget.controller.hasError) {
          return CommonErrorWidget(
            message: widget.controller.errorMessage ?? 'Bilinmeyen hata',
            onRetry: () => widget.controller.loadInitial(),
          );
        }

        if (widget.controller.isEmpty) {
          return CommonEmptyWidget(
            title: widget.emptyTitle,
            subtitle: widget.emptySubtitle,
            icon: widget.emptyIcon,
            actionLabel: widget.emptyActionLabel,
            onActionTap: widget.onEmptyAction,
            color: widget.color,
          );
        }

        Widget listView = ListView.builder(
          controller: _scrollController,
          padding: widget.padding ?? const EdgeInsets.all(16),
          physics: widget.physics,
          itemCount: _calculateItemCount(),
          itemBuilder: (context, index) {
            // Header
            if (widget.header != null && index == 0) {
              return widget.header!;
            }

            // Adjust index for header
            final adjustedIndex = widget.header != null ? index - 1 : index;

            // List items
            if (adjustedIndex < widget.controller.items.length) {
              final item = widget.controller.items[adjustedIndex];
              Widget itemWidget =
                  widget.itemBuilder(context, item, adjustedIndex);

              // Add spacing between items
              if (widget.itemSpacing != null && adjustedIndex > 0) {
                itemWidget = Padding(
                  padding: EdgeInsets.only(top: widget.itemSpacing!),
                  child: itemWidget,
                );
              }

              return itemWidget;
            }

            // Loading more indicator
            if (widget.controller.isLoadingMore) {
              return const PaginationLoadingWidget();
            }

            return const SizedBox.shrink();
          },
        );

        if (widget.enablePullToRefresh) {
          return RefreshIndicator(
            onRefresh: () => widget.controller.refresh(),
            color: widget.color,
            child: listView,
          );
        }

        return listView;
      },
    );
  }

  int _calculateItemCount() {
    int count = widget.controller.items.length;

    // Add header
    if (widget.header != null) {
      count += 1;
    }

    // Add loading indicator
    if (widget.controller.isLoadingMore) {
      count += 1;
    }

    return count;
  }
}

class PaginatedGridView<T> extends StatefulWidget {
  final BaseListController<T> controller;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final double? childAspectRatio;
  final EdgeInsets? padding;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final Color? color;
  final bool enablePullToRefresh;

  const PaginatedGridView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.crossAxisCount,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1,
    this.padding,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.color,
    this.enablePullToRefresh = true,
  });

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (widget.controller.items.isEmpty && !widget.controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadInitial();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return CommonLoadingWidget(
            message: 'Veriler yükleniyor...',
            color: widget.color,
          );
        }

        if (widget.controller.hasError) {
          return CommonErrorWidget(
            message: widget.controller.errorMessage ?? 'Bilinmeyen hata',
            onRetry: () => widget.controller.loadInitial(),
          );
        }

        if (widget.controller.isEmpty) {
          return CommonEmptyWidget(
            title: widget.emptyTitle,
            subtitle: widget.emptySubtitle,
            icon: widget.emptyIcon,
            actionLabel: widget.emptyActionLabel,
            onActionTap: widget.onEmptyAction,
            color: widget.color,
          );
        }

        Widget gridView = CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: widget.padding ?? const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.crossAxisCount,
                  mainAxisSpacing: widget.mainAxisSpacing ?? 8,
                  crossAxisSpacing: widget.crossAxisSpacing ?? 8,
                  childAspectRatio: widget.childAspectRatio ?? 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < widget.controller.items.length) {
                      final item = widget.controller.items[index];
                      return widget.itemBuilder(context, item, index);
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: widget.controller.items.length,
                ),
              ),
            ),
            if (widget.controller.isLoadingMore)
              const SliverToBoxAdapter(
                child: PaginationLoadingWidget(),
              ),
          ],
        );

        if (widget.enablePullToRefresh) {
          return RefreshIndicator(
            onRefresh: () => widget.controller.refresh(),
            color: widget.color,
            child: gridView,
          );
        }

        return gridView;
      },
    );
  }
}
