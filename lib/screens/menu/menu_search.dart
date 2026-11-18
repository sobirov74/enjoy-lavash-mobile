part of 'package:enjoy_lavash_mobile/screens/menu_screen.dart';

/// Menu search: the field under the title, results from every category, the
/// pinned results bar and search shortcut, and the "nothing found" state.
///
/// While a query is typed the category chips give way to the results bar;
/// the selected category comes back unchanged when the search is cleared.
extension _MenuSearch on _MenuScreenState {
  Widget _buildSearchField(L t) {
    return AppSearchField(
      key: const ValueKey<String>('menu-search-field'),
      controller: _searchController,
      focusNode: _searchFocus,
      hintText: t.menuSearchHint,
      clearTooltip: t.menuSearchClear,
      onChanged: _setSearchQuery,
      onClear: _clearSearch,
    );
  }

  void _setSearchQuery(String text) {
    final query = text.trim();
    if (query == _searchQuery) return;
    final wasSearching = _isSearching;
    _cartAnimation.cancel();
    _updateState(() => _searchQuery = query);
    if (wasSearching && !_isSearching) _restoreCategoryHeader();
  }

  void _clearSearch() {
    _searchController.clear();
    _setSearchQuery('');
  }

  /// The category chips were not built while searching. Once they are back,
  /// measure the selection pill again and bring the selected chip into view.
  void _restoreCategoryHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollSelectedChipIntoView();
      _updateCategoryPillGeometry();
    });
  }

  /// Products matching [query], from an index built once per catalog and
  /// results kept until the query or the catalog changes.
  List<MenuProduct> _searchResultsFor(String query) {
    var index = _searchIndex;
    if (index == null || !identical(index.products, widget.products)) {
      index = _searchIndex = MenuSearchIndex(widget.products);
    }
    final cached = _searchResults;
    if (cached != null &&
        identical(cached.index, index) &&
        cached.query == query) {
      return cached.results;
    }
    final results = index.search(query);
    _searchResults = (index: index, query: query, results: results);
    return results;
  }

  /// Scrolls back to the field and opens the keyboard.
  Future<void> _focusSearchField() async {
    _cartAnimation.cancel();
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      if (AppMotion.reduced(context)) {
        _scrollController.jumpTo(0);
      } else {
        await _scrollController.animateTo(
          0,
          duration: AppMotion.state,
          curve: AppMotion.enter,
        );
      }
    }
    if (mounted) _searchFocus.requestFocus();
  }

  /// A round search button at the start of the pinned header, shown only
  /// once the field has scrolled out of view.
  Widget _buildSearchShortcut(L t) {
    return ValueListenableBuilder<bool>(
      valueListenable: _searchFieldHidden,
      builder: (context, hidden, _) => AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.state),
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) => SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          alignment: AlignmentDirectional.centerStart,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: hidden
            ? Padding(
                key: const ValueKey<String>('menu-search-shortcut'),
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: t.menuSearchOpen,
                  child: Semantics(
                    button: true,
                    child: Material(
                      color: AppDesignTokens.surface(context),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => unawaited(_focusSearchField()),
                        child: SizedBox.square(
                          dimension: AppDesignTokens.chipHeight,
                          child: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppDesignTokens.primaryText(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  /// Takes the chips' place in the pinned header while searching.
  Widget _buildSearchSummary(L t, int resultCount) {
    return FadeSlideIn(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              t.menuSearchResults(resultCount),
              key: const ValueKey<String>('menu-search-summary'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.ui(
                size: 14,
                weight: FontWeight.w600,
                color: AppDesignTokens.secondaryText(context),
              ),
            ),
          ),
          TextButton.icon(
            key: const ValueKey<String>('menu-search-summary-clear'),
            onPressed: _clearSearch,
            style: TextButton.styleFrom(
              foregroundColor: AppDesignTokens.action,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(t.menuSearchClear),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState(L t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 96),
        child: FadeSlideIn(
          child: Column(
            key: const ValueKey<String>('menu-search-empty'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppDesignTokens.surface(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  color: AppDesignTokens.tertiaryText(context),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              TypographyText(
                t.menuSearchNoResults(_searchQuery),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.ui(
                  size: 17,
                  weight: FontWeight.w600,
                  color: AppDesignTokens.primaryText(context),
                ),
              ),
              const SizedBox(height: 6),
              TypographyText(
                t.menuSearchNoResultsHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.ui(
                  size: 14,
                  color: AppDesignTokens.secondaryText(context),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const ValueKey<String>('menu-search-empty-clear'),
                onPressed: _clearSearch,
                child: Text(t.menuSearchClear),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
